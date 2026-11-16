#!/usr/bin/env python3
"""
File        : asm.py
Description : Two-pass assembler for the 8-bit von Neumann CPU. Turns an
              assembly source file into program.mem, the text file that
              memory.vhd loads at elaboration.
Usage       : python3 tools/asm.py programs/test.asm -o rtl/program.mem
Notes       : Python 3, standard library only.
              Syntax, one instruction per line:
                  label:                  ; a label alone on a line
                  loop:  DEC R3           ; or before an instruction
                  LDI    R0, 0F           ; numbers are hex: 0F, FF, 0x3C
                  LDR    R1, [R3]         ; register-indirect
                  JNZ    loop             ; labels anywhere an address goes
              Comments start with ';'. Mnemonics, registers and labels are
              case-insensitive. Labels start with a letter or '_', and must not
              be a mnemonic, a register name, or valid hex (e.g. 'BE', 'CAFE'),
              so a number and a label can never be confused.
              Pass 1 records each label's byte address (3 x instruction index);
              pass 2 encodes each instruction as 24 bits: opcode, rd/rs, imm.
              Every error is reported as file:line: message, and no output file
              is written if there is any error.
              Output: one instruction per line as 6 hex digits, followed by a
              comment with its byte address and the source line.
"""

import argparse
import re
import sys

# Opcodes, as in cpu_pkg.vhd, and the operand pattern of each instruction.
#   none      : no operands                    op 0  0  00
#   rd        : one register                   op rd 0  00
#   rd_rs     : two registers                  op rd rs 00
#   rd_imm    : register, 8-bit value          op rd 0  imm
#   addr      : 8-bit address or label         op 0  0  addr
#   rd_ind    : register, [register]           op rd rs 00
INSTRUCTIONS = {
    "NOP":  (0x00, "none"),
    "LDI":  (0x01, "rd_imm"),
    "MOV":  (0x02, "rd_rs"),
    "LD":   (0x03, "rd_imm"),
    "ST":   (0x04, "rd_imm"),
    "ADD":  (0x05, "rd_rs"),
    "SUB":  (0x06, "rd_rs"),
    "AND":  (0x07, "rd_rs"),
    "OR":   (0x08, "rd_rs"),
    "XOR":  (0x09, "rd_rs"),
    "NOT":  (0x0A, "rd"),
    "CMP":  (0x0B, "rd_rs"),
    "JMP":  (0x0C, "addr"),
    "JZ":   (0x0D, "addr"),
    "JNZ":  (0x0E, "addr"),
    "JC":   (0x0F, "addr"),
    "SHL":  (0x10, "rd"),
    "SHR":  (0x11, "rd"),
    "INC":  (0x12, "rd"),
    "DEC":  (0x13, "rd"),
    "PUSH": (0x14, "rd"),
    "POP":  (0x15, "rd"),
    "CALL": (0x16, "addr"),
    "RET":  (0x17, "none"),
    "LDR":  (0x18, "rd_ind"),
    "STR":  (0x19, "rd_ind"),
}

OPERAND_COUNT = {"none": 0, "rd": 1, "addr": 1, "rd_rs": 2, "rd_imm": 2, "rd_ind": 2}

MAX_INSTRUCTIONS = 85       # 85 x 3 = 255 bytes in a 256-byte memory
NUM_REGISTERS = 4           # R0-R3

LABEL_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
HEX_RE = re.compile(r"^(0[xX])?[0-9A-Fa-f]+$")


class AsmError(Exception):
    """An error tied to one source line."""


    def __init__(self, line_no, message):
        super().__init__(message)
        self.line_no = line_no
        self.message = message


def parse_number(text, line_no, what):
    """Parses a hex number (0F, FF, 0x3C) in the range 00-FF."""
    if not HEX_RE.match(text):
        raise AsmError(line_no, f"bad {what} '{text}' (expected hex, e.g. 0F)")
    value = int(text, 16)
    if value > 0xFF:
        raise AsmError(line_no, f"{what} '{text}' out of range (max FF)")
    return value


def parse_register(text, line_no):
    """Parses R0-R3 and returns the register number."""
    m = re.match(r"^[Rr](\d+)$", text)
    if not m or int(m.group(1)) >= NUM_REGISTERS:
        raise AsmError(line_no, f"bad register '{text}' (expected R0-R{NUM_REGISTERS - 1})")
    return int(m.group(1))


def split_line(raw):
    """Splits a source line into (label, mnemonic, operands, comment)."""
    code, _, comment = raw.partition(";")
    code = code.strip()
    comment = comment.strip()

    label = None
    if ":" in code:
        label, _, code = code.partition(":")
        label = label.strip()
        code = code.strip()


    if not code:
        return label, None, [], comment


    parts = code.split(None, 1)
    mnemonic = parts[0].upper()
    operands = []
    if len(parts) > 1:
        operands = [op.strip() for op in parts[1].split(",")]
    return label, mnemonic, operands, comment


def pass1(lines, errors):
    """Records each label's byte address and collects the instructions."""
    labels = {}
    instructions = []       # (line_no, mnemonic, operands, source, comment)
    pending = []            # labels waiting for their instruction

    for line_no, raw in enumerate(lines, start=1):
        try:
            label, mnemonic, operands, comment = split_line(raw)

            if label is not None:
                if not LABEL_RE.match(label):
                    raise AsmError(line_no, f"bad label '{label}'")
                if HEX_RE.match(label):
                    raise AsmError(line_no, f"label '{label}' looks like a hex number")
                if label.upper() in INSTRUCTIONS or re.match(r"^[Rr]\d+$", label):
                    raise AsmError(line_no, f"label '{label}' is a reserved word")
                key = label.upper()
                if key in labels:
                    raise AsmError(line_no, f"duplicate label '{label}'")
                labels[key] = 3 * len(instructions)
                pending.append(label)

            if mnemonic is not None:
                if mnemonic not in INSTRUCTIONS:
                    raise AsmError(line_no, f"unknown instruction '{mnemonic}'")
                source = raw.partition(";")[0].strip()
                if label is not None:
                    source = source.partition(":")[2].strip()
                source = " ".join(source.split())      # collapse spacing
                if pending:
                    source = ": ".join(pending) + ": " + source
                    pending = []
                instructions.append((line_no, mnemonic, operands, source, comment))
        except AsmError as e:
            errors.append(e)

    if len(instructions) > MAX_INSTRUCTIONS:
        line_no = instructions[MAX_INSTRUCTIONS][0]
        errors.append(AsmError(line_no, f"program too long (max {MAX_INSTRUCTIONS} instructions)"))
    
    return labels, instructions


def encode(line_no, mnemonic, operands, labels):
    """Builds the 24-bit word for one instruction."""
    opcode, pattern = INSTRUCTIONS[mnemonic]

    expected = OPERAND_COUNT[pattern]
    if len(operands) != expected or any(op == "" for op in operands):
        raise AsmError(line_no, f"{mnemonic} takes {expected} operand(s), got {len([o for o in operands if o])}")

    rd = rs = imm = 0
    if pattern == "rd":
        rd = parse_register(operands[0], line_no)
    elif pattern == "rd_rs":
        rd = parse_register(operands[0], line_no)
        rs = parse_register(operands[1], line_no)
    elif pattern == "rd_imm":
        rd = parse_register(operands[0], line_no)
        imm = parse_number(operands[1], line_no, "value")
    elif pattern == "addr":
        target = operands[0]
        if target.upper() in labels:
            imm = labels[target.upper()]
        elif HEX_RE.match(target):
            imm = parse_number(target, line_no, "address")
        else:
            raise AsmError(line_no, f"undefined label '{target}'")
    elif pattern == "rd_ind":
        rd = parse_register(operands[0], line_no)
        m = re.match(r"^\[\s*(\S+)\s*\]$", operands[1])
        if not m:
            raise AsmError(line_no, f"{mnemonic} needs [Rn] as second operand, got '{operands[1]}'")
        rs = parse_register(m.group(1), line_no)

    return (opcode << 16) | (rd << 12) | (rs << 8) | imm


def assemble(lines):
    """Returns (output lines, errors)."""
    errors = []
    labels, instructions = pass1(lines, errors)

    out = []
    for index, (line_no, mnemonic, operands, source, comment) in enumerate(instructions):
        try:
            word = encode(line_no, mnemonic, operands, labels)
            note = f"{source:<22} {comment}".rstrip() if comment else source
            out.append(f"{word:06X}   -- {3 * index:02X}: {note}")
        except AsmError as e:
            errors.append(e)

    errors.sort(key=lambda e: e.line_no)
    return out, errors


def main():
    parser = argparse.ArgumentParser(description="Assembler for the 8-bit von Neumann CPU")
    parser.add_argument("source", help="assembly source file (.asm)")
    parser.add_argument("-o", "--output", default="program.mem",
                        help="output file (default: program.mem)")
    args = parser.parse_args()

    try:
        with open(args.source) as f:
            lines = f.read().splitlines()
    except OSError as e:
        print(f"error: cannot read {args.source}: {e.strerror}", file=sys.stderr)
        return 1

    out, errors = assemble(lines)

    if errors:
        for e in errors:
            print(f"{args.source}:{e.line_no}: {e.message}", file=sys.stderr)
        print(f"{len(errors)} error(s), {args.output} not written", file=sys.stderr)
        return 1

    header = [
        f"-- program.mem: generated by tools/asm.py from {args.source}",
        "-- One instruction per line: 6 hex digits = opcode, rd/rs, imm.",
        "-- Instruction n is stored at addresses 3n, 3n+1, 3n+2.",
        "-- Lines starting with -- and blank lines are skipped;",
        "-- text after the 6 digits is ignored.",
        "",
    ]
    with open(args.output, "w") as f:
        f.write("\n".join(header + out) + "\n")

    print(f"{args.source}: {len(out)} instructions ({3 * len(out)} bytes) -> {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())