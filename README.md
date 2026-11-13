# 8-bit CPU in VHDL — Multi-cycle version

A simple 8-bit, **multi-cycle**, Harvard-architecture CPU written in VHDL and
verified with self-checking testbenches in the Vivado behavioral simulator (XSIM).

This branch converts the single-cycle CPU on `main` into a multi-cycle design.
An instruction register holds each instruction while a finite-state-machine
(FSM) control unit steps it through FETCH, DECODE, EXECUTE and WRITEBACK, taking
3 or 4 clocks per instruction.

The instruction set has since been **extended from 16 to 20 instructions**
(SHL, SHR, INC, DEC). To make room, the instruction word grew from 16 to 24 bits
with byte-aligned fields, the opcode from 4 to 8 bits and the ALU select from
3 to 4 bits. See [ISA extension](#isa-extension) for what changed.

**Status:** RTL complete. All 11 testbenches pass.

> **Branches**
>
> | Branch | Version | Status |
> |---|---|---|
> | `main` | Single-cycle CPU, 16-bit instructions (tag `v1.0-single-cycle`) | Complete and verified |
> | `multicycle` | Multi-cycle CPU with an FSM control unit, 24-bit instructions, 20 instructions | Complete and verified (this branch) |
>
> The earlier multi-cycle version with 16-bit instructions and 16 opcodes is in this branch's commit history.

---

## Table of contents

- [Features](#features)
- [Single-cycle vs multi-cycle](#single-cycle-vs-multi-cycle)
- [ISA extension](#isa-extension)
- [Architecture](#architecture)
  - [Design decisions](#design-decisions)
  - [Datapath](#datapath)
  - [Control FSM](#control-fsm)
  - [Cycles per instruction](#cycles-per-instruction)
  - [Writeback multiplexer](#writeback-multiplexer)
- [Instruction set](#instruction-set)
- [ALU](#alu)
- [Control unit](#control-unit)
- [Components](#components)
- [Project structure](#project-structure)
- [Running the simulation](#running-the-simulation)
- [Verification](#verification)
- [Writing your own program](#writing-your-own-program)
- [Limitations](#limitations)
- [Future work](#future-work)

---

## Features

- 8-bit data path, 8-bit program counter (256 instruction addresses)
- 24-bit byte-aligned instruction word, 20 instructions (8-bit opcode, room for 256)
- Harvard architecture: separate 256 x 24 instruction ROM and 256 x 8 data RAM
- Four 8-bit general-purpose registers (R0-R3)
- Zero (Z) and Carry (C) flags with independent load enables
- **Multi-cycle execution:** 3 or 4 clocks per instruction, driven by a 4-state FSM
- 24-bit instruction register (IR) holding the instruction for the whole sequence
- Shift left/right and increment/decrement, with the shifted-out bit or overflow in C
- Unused opcodes decode safely as NOP
- Synchronous reset
- Point-to-point datapath with multiplexers (no tri-state bus)
- Self-checking testbenches for every component, plus a full-system testbench that checks the FSM state on every cycle

---

## Single-cycle vs multi-cycle

| | Single-cycle (`main`) | Multi-cycle (this branch) |
|---|---|---|
| Clocks per instruction | 1 | 3 or 4 |
| Control unit | Combinational `case` on the opcode | FSM: state register + next-state logic + output logic |
| Instruction register | None (ROM output used directly) | 24-bit IR, loaded in FETCH |
| Instruction word | 16 bits, 4-bit opcode | 24 bits, 8-bit opcode |
| Instructions | 16 | 20 |
| When things are written | Everything on the same edge | Each write only in its own state |
| `pc_inc` | Always 1 | 1 only in FETCH |
| Test program, reset to halt | 16 cycles | 72 cycles |
| Debug outputs | `pc`, `instr`, `reg_a`, `z`, `c` | Same, plus `state_dbg` |

The multi-cycle design is slower per instruction in clock count, but each
clock does less work, so the critical path is shorter. It is also the starting
point for designs with synchronous memories or a shared instruction/data memory.

---

## ISA extension

The 16-bit format had no free opcodes (4 bits, all 16 used) and only two spare
ALU codes (3 bits, `110` and `111`), so four new ALU instructions did not fit.
The format was widened instead of squeezed:

| Item | Before | After |
|---|---|---|
| Instruction word | 16 bits | **24 bits**, byte-aligned |
| Opcode | 4 bits (16 used of 16) | **8 bits** (20 used of 256) |
| rd / rs fields | 2 bits each | **4 bits each** (only the low 2 bits are wired; R0-R3) |
| imm | 8 bits | 8 bits |
| ALU select | 3 bits (6 used of 8) | **4 bits** (10 used of 16) |
| Register constants `REG0`-`REG3` | 2 bits | 4 bits |
| Instructions | 16 | **20**: added SHL, SHR, INC, DEC |

Byte-aligned fields make every instruction readable straight from its hex:
digits 1-2 are the opcode, digit 3 is rd, digit 4 is rs and digits 5-6 are imm
(`122000` = opcode `12` INC, rd `2`, rs `0`, imm `00`).

Files changed:

| File | Change |
|---|---|
| `cpu_pkg.vhd` | 8-bit `OP_*`, 4-bit `ALU_*` and `REG*`; new `OP_SHL`-`OP_DEC` and `ALU_SHL`-`ALU_DEC` |
| `alu.vhd` | 4-bit `alu_sel`; SHL, SHR, INC, DEC with carry |
| `ir.vhd` | 24-bit |
| `instr_rom.vhd` | 256 x 24; program extended to use the new instructions |
| `control_unit.vhd` | 8-bit opcode, 4-bit `alu_sel`; new opcodes take the full 4-state path and load Z and C |
| `cpu.vhd` | 24-bit IR/ROM signals; opcode `instr(23:16)`, rd `instr(13:12)`, rs `instr(9:8)` |
| `tb_alu`, `tb_ir`, `tb_instr_rom`, `tb_control_unit`, `tb_cpu` | Updated widths, new tests and a new expected trace |

The PC, register file, flags register, data RAM, writeback mux and `mux2` are
unchanged.

---

## Architecture

### Design decisions

| Topic | Decision | Reason |
|---|---|---|
| Memory model | Harvard: separate instruction ROM and data RAM | Fetch and data access never collide. A program cannot overwrite its own code |
| Interconnect | Point-to-point wiring plus a writeback multiplexer | FPGA fabric has no internal tri-state buses; multiplexers avoid conflicting drivers |
| Data width | 8 bits | Registers, ALU and RAM are all 8 bits wide |
| Instruction width | 24 bits, byte-aligned | Room for an 8-bit opcode and an 8-bit immediate; every field is whole hex digits |
| Registers | 4 x 8-bit (R0-R3) | The 4-bit rd/rs fields leave room for 16 registers; only 2 bits of each are wired today |
| Opcode decoding | All 8 bits decoded; unused opcodes fall to `others` | No aliasing: opcode `14`-`FF` behave as NOP instead of repeating real instructions |
| Control | Multi-cycle FSM, 4 states | Each instruction uses only the states it needs (3 or 4) |
| Holding registers | IR only | Registers change only in WRITEBACK, so ALU inputs and result stay stable from DECODE to WRITEBACK without A/B/ALUOut registers |
| Selects vs enables | Selects (`alu_sel`, `wb_sel`) from the opcode only; enables from the state | Selects choose *what*; enables decide *when*. Keeps the output logic simple |
| Reset | Synchronous, highest priority | PC, IR, register file, flags register and FSM (back to FETCH). The data RAM has no reset |
| Flags | Zero and Carry only | Enough for JZ, JNZ and JC |
| Carry on SUB | Borrow convention: C = 1 when a < b | `JC` after `CMP a, b` means "jump if a < b" (unsigned) |
| Carry on shifts | C = the bit shifted out | Lets a program test the dropped bit with `JC` |

### Datapath

```mermaid
flowchart LR
    PC["Program Counter<br/>pc"] -->|"pc_val (8)"| ROM["Instruction ROM<br/>instr_rom<br/>256 x 24"]
    ROM -->|"rom_out (24)"| IR["Instruction Register<br/>ir"]

    IR -->|"instr(23:16) opcode"| CU["Control FSM<br/>control_unit"]
    IR -->|"instr(13:12) rd"| RF["Register File<br/>reg_file<br/>R0-R3"]
    IR -->|"instr(9:8) rs"| RF
    IR -->|"instr(7:0) imm"| IMM(("imm"))

    IMM -->|"jump_addr"| PC
    IMM -->|"addr"| RAM["Data RAM<br/>data_ram<br/>256 x 8"]
    IMM -->|"imm"| WB["Writeback Mux<br/>wb_mux"]

    RF -->|"reg_a (rd)"| ALU["ALU<br/>alu"]
    RF -->|"reg_b (rs)"| ALU
    RF -->|"reg_a (rd)"| RAM
    RF -->|"reg_b (rs)"| WB

    ALU -->|"alu_result"| WB
    RAM -->|"ram_out"| WB
    WB -->|"wb_data"| RF

    ALU -->|"zero, carry"| FL["Flags Register<br/>flags_reg"]
    FL -->|"z_flag, c_flag"| CU

    CU -. "ir_load" .-> IR
    CU -. "pc_load, pc_inc" .-> PC
    CU -. "reg_wr_en" .-> RF
    CU -. "alu_sel (4)" .-> ALU
    CU -. "ram_wr_en" .-> RAM
    CU -. "z_load, c_load" .-> FL
    CU -. "wb_sel" .-> WB
```

Solid arrows are data; dotted arrows are control signals from the FSM.

The only datapath change from `main` is the IR between the ROM and the
instruction fields. Every `instr(...)` slice comes from the IR, so the
instruction stays stable while the FSM steps through its states, even though
the PC has already moved on to the next address. Bits 15:14 and 11:10 (the
upper halves of rd and rs) are reserved and not connected.

### Control FSM

```mermaid
stateDiagram-v2
    [*] --> FETCH: rst
    FETCH --> DECODE
    DECODE --> WRITEBACK: LDI, MOV
    DECODE --> EXECUTE: all other opcodes
    EXECUTE --> WRITEBACK: ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, INC, DEC, LD
    EXECUTE --> FETCH: NOP, ST, CMP, JMP, JZ, JNZ, JC, unused
    WRITEBACK --> FETCH
```

| State | Work done | Enables active |
|---|---|---|
| FETCH | IR loads `ROM[PC]`; PC increments | `ir_load`, `pc_inc` |
| DECODE | Opcode stable in the IR; register reads settle; next state chosen from the opcode | none |
| EXECUTE | ALU result settles; flags load; ST writes RAM; jumps load the PC | `z_load`, `c_load`, `ram_wr_en`, `pc_load` (per opcode) |
| WRITEBACK | Result written to rd | `reg_wr_en` |

Why it works without extra holding registers:

- **PC+1 happens in FETCH, a jump loads in EXECUTE.** They never collide; a taken jump overwrites the already-incremented PC.
- **The register file only changes in WRITEBACK.** ALU inputs, and therefore its result, are stable from DECODE through WRITEBACK.
- **Flags load in EXECUTE.** They are stable by the time any later jump reads them.

### Cycles per instruction

| Instructions | Path | Clocks |
|---|---|---|
| NOP, ST, CMP, JMP, JZ, JNZ, JC, unused opcodes | FETCH → DECODE → EXECUTE | 3 |
| LDI, MOV | FETCH → DECODE → WRITEBACK | 3 |
| ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, INC, DEC, LD | FETCH → DECODE → EXECUTE → WRITEBACK | 4 |

### Writeback multiplexer

`wb_mux` is a 4-to-1 multiplexer built from three 2-to-1 multiplexers (`mux2`):

```mermaid
flowchart LR
    A["ALU result"] -->|"in0"| MA["mux_a<br/>sel = wb_sel(0)"]
    R["RAM data"] -->|"in1"| MA
    I["imm"] -->|"in0"| MB["mux_b<br/>sel = wb_sel(0)"]
    B["reg_b (rs)"] -->|"in1"| MB
    MA -->|"in0"| MC["mux_c<br/>sel = wb_sel(1)"]
    MB -->|"in1"| MC
    MC --> W["wb_data<br/>to register file"]
```

| wb_sel | Constant | Source | Used by |
|---|---|---|---|
| 00 | `WB_ALU` | ALU result | ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, INC, DEC |
| 01 | `WB_RAM` | Data RAM | LD |
| 10 | `WB_IMM` | Immediate | LDI |
| 11 | `WB_REG` | rs register | MOV |

---

## Instruction set

### Instruction format

```
 23            16 15    12 11     8 7             0
+----------------+--------+--------+---------------+
|     opcode     |   rd   |   rs   |      imm      |
+----------------+--------+--------+---------------+
      8 bits       4 bits   4 bits      8 bits
```

Unused fields are 0. Only R0-R3 exist, so the upper 2 bits of rd and rs must
be 0. In hexadecimal: digits 1-2 are the opcode, digit 3 is rd, digit 4 is rs,
digits 5-6 are imm.

### Instructions

| Opcode | Mnemonic | Operation | Flags |
|---|---|---|---|
| 00 | `NOP` | No operation | - |
| 01 | `LDI rd, imm` | rd = imm | - |
| 02 | `MOV rd, rs` | rd = rs | - |
| 03 | `LD rd, addr` | rd = RAM[addr] | - |
| 04 | `ST rd, addr` | RAM[addr] = rd | - |
| 05 | `ADD rd, rs` | rd = rd + rs | Z, C |
| 06 | `SUB rd, rs` | rd = rd - rs | Z, C |
| 07 | `AND rd, rs` | rd = rd and rs | Z |
| 08 | `OR rd, rs` | rd = rd or rs | Z |
| 09 | `XOR rd, rs` | rd = rd xor rs | Z |
| 0A | `NOT rd` | rd = not rd | Z |
| 0B | `CMP rd, rs` | Compute rd - rs, set flags, discard result | Z, C |
| 0C | `JMP addr` | PC = addr | - |
| 0D | `JZ addr` | PC = addr if Z = 1 | - |
| 0E | `JNZ addr` | PC = addr if Z = 0 | - |
| 0F | `JC addr` | PC = addr if C = 1 | - |
| 10 | `SHL rd` | rd = rd shifted left one bit, 0 into bit 0 | Z, C |
| 11 | `SHR rd` | rd = rd shifted right one bit (logical), 0 into bit 7 | Z, C |
| 12 | `INC rd` | rd = rd + 1 | Z, C |
| 13 | `DEC rd` | rd = rd - 1 | Z, C |
| 14-FF | (unused) | Behaves as NOP | - |

`JMP` to its own address acts as a halt (the FSM keeps cycling FETCH, DECODE, EXECUTE on it).

### Flags

| Flag | Set when | Updated by | Read by |
|---|---|---|---|
| Z (zero) | ALU result is 00 | ADD, SUB, CMP, AND, OR, XOR, NOT, SHL, SHR, INC, DEC | JZ, JNZ |
| C (carry) | See the table below | ADD, SUB, CMP, SHL, SHR, INC, DEC | JC |

| Instruction | C = 1 when |
|---|---|
| ADD | The sum overflows past FF |
| SUB, CMP | Borrow: rd < rs |
| SHL | Bit 7 of rd was 1 (shifted out) |
| SHR | Bit 0 of rd was 1 (shifted out) |
| INC | rd was FF (wraps to 00) |
| DEC | rd was 00 (borrow, wraps to FF) |

Logic operations update Z but keep C, so the flags register has a separate load enable per flag.

---

## ALU

`alu.vhd` is combinational. `alu_sel` is 4 bits; carry/borrow is computed with
a 9-bit unsigned intermediate.

| Code | Constant | Result | Carry |
|---|---|---|---|
| 0000 | `ALU_ADD` | a + b | Overflow |
| 0001 | `ALU_SUB` | a - b | Borrow |
| 0010 | `ALU_AND` | a and b | 0 |
| 0011 | `ALU_OR` | a or b | 0 |
| 0100 | `ALU_XOR` | a xor b | 0 |
| 0101 | `ALU_NOT` | not a | 0 |
| 0110 | `ALU_SHL` | a(6:0) & '0' | a(7) |
| 0111 | `ALU_SHR` | '0' & a(7:1) | a(0) |
| 1000 | `ALU_INC` | a + 1 | Overflow |
| 1001 | `ALU_DEC` | a - 1 | Borrow |
| 1010-1111 | (spare) | 00 | 0 |

The unary operations (NOT, SHL, SHR, INC, DEC) use only `a` (rd) and ignore `b`.

---

## Control unit

`control_unit.vhd` is a three-process FSM:

| Process | Type | Contents |
|---|---|---|
| `state_reg` | Clocked | Synchronous reset to FETCH, otherwise `state <= next_state` |
| `next_state_logic` | Combinational | Transition table below |
| `output_logic` | Combinational | Defaults, then selects from the opcode, then enables from the state |

The state type `state_t` is declared in `cpu_pkg`, so it can appear on ports and the waveform shows state names.

### Next state

| Current | Condition | Next |
|---|---|---|
| FETCH | always | DECODE |
| DECODE | LDI, MOV | WRITEBACK |
| DECODE | otherwise | EXECUTE |
| EXECUTE | ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, INC, DEC, LD | WRITEBACK |
| EXECUTE | otherwise | FETCH |
| WRITEBACK | always | FETCH |

### Selects (from the opcode, in every state)

| Opcode | alu_sel | wb_sel |
|---|---|---|
| ADD | ADD | ALU |
| SUB, CMP | SUB | ALU |
| AND / OR / XOR / NOT | AND / OR / XOR / NOT | ALU |
| SHL / SHR / INC / DEC | SHL / SHR / INC / DEC | ALU |
| LDI | ADD | IMM |
| MOV | ADD | REG |
| LD | ADD | RAM |
| others | ADD | ALU |

### Enables (by state)

| State | Opcode | Enables = 1 |
|---|---|---|
| FETCH | any | `ir_load`, `pc_inc` |
| DECODE | any | none |
| EXECUTE | ADD, SUB, CMP, SHL, SHR, INC, DEC | `z_load`, `c_load` |
| EXECUTE | AND, OR, XOR, NOT | `z_load` |
| EXECUTE | ST | `ram_wr_en` |
| EXECUTE | JMP | `pc_load` |
| EXECUTE | JZ / JNZ / JC | `pc_load` = Z / not Z / C |
| EXECUTE | NOP, LD, unused | none |
| WRITEBACK | any | `reg_wr_en` |

---

## Components

| Entity | File | Type | Description |
|---|---|---|---|
| `cpu_pkg` | `cpu_pkg.vhd` | Package | 8-bit `OP_*`, 4-bit `ALU_*`, 4-bit `REG0`-`REG3`, 2-bit `WB_*` constants and the FSM state type `state_t` |
| `cpu` | `cpu.vhd` | Structural | Top level; instantiates and wires every component. Exposes debug outputs |
| `pc` | `pc.vhd` | Sequential | 8-bit program counter. Priority: reset > load > increment > hold |
| `instr_rom` | `instr_rom.vhd` | Combinational | 256 x 24 instruction ROM, asynchronous read |
| `ir` | `ir.vhd` | Sequential | 24-bit instruction register, loaded in FETCH |
| `control_unit` | `control_unit.vhd` | Sequential (FSM) | 4-state control FSM |
| `reg_file` | `reg_file.vhd` | Sequential | 4 x 8-bit registers, two asynchronous read ports, one synchronous write port |
| `alu` | `alu.vhd` | Combinational | ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, INC, DEC with zero and carry outputs |
| `flags_reg` | `flags_reg.vhd` | Sequential | Stores Z and C with independent load enables |
| `data_ram` | `data_ram.vhd` | Sequential | 256 x 8 data RAM, synchronous write, asynchronous read, no reset |
| `wb_mux` | `wb_mux.vhd` | Structural | 4-to-1 writeback multiplexer built from three `mux2` |
| `mux2` | `mux2.vhd` | Combinational | 8-bit 2-to-1 multiplexer (gate-level) |

### Component hierarchy

```mermaid
flowchart TD
    CPU["cpu"] --> PC["pc"]
    CPU --> ROM["instr_rom"]
    CPU --> IR["ir"]
    CPU --> CU["control_unit"]
    CPU --> RF["reg_file"]
    CPU --> ALU["alu"]
    CPU --> RAM["data_ram"]
    CPU --> FL["flags_reg"]
    CPU --> WB["wb_mux"]
    WB --> M1["mux2 (mux_a)"]
    WB --> M2["mux2 (mux_b)"]
    WB --> M3["mux2 (mux_c)"]
    PKG["cpu_pkg"] -. used by .-> ROM
    PKG -. used by .-> CU
    PKG -. used by .-> ALU
    PKG -. used by .-> CPU
```

### Debug outputs

| Port | Width | Shows |
|---|---|---|
| `pc_dbg` | 8 | Program counter (already the next address after FETCH) |
| `instr_dbg` | 24 | Instruction register |
| `reg_a_dbg` | 8 | Value of the rd register of the instruction in the IR |
| `z_dbg` | 1 | Stored zero flag |
| `c_dbg` | 1 | Stored carry flag |
| `state_dbg` | `state_t` | Current FSM state |

---

## Project structure

```
8-bit-cpu/
├── rtl/
│   ├── cpu_pkg.vhd
│   ├── cpu.vhd
│   ├── pc.vhd
│   ├── instr_rom.vhd
│   ├── ir.vhd
│   ├── control_unit.vhd
│   ├── reg_file.vhd
│   ├── alu.vhd
│   ├── flags_reg.vhd
│   ├── data_ram.vhd
│   ├── wb_mux.vhd
│   └── mux2.vhd
├── tb/
│   ├── tb_cpu.vhd
│   ├── tb_pc.vhd
│   ├── tb_instr_rom.vhd
│   ├── tb_ir.vhd
│   ├── tb_control_unit.vhd
│   ├── tb_reg_file.vhd
│   ├── tb_alu.vhd
│   ├── tb_flags_reg.vhd
│   ├── tb_data_ram.vhd
│   ├── tb_wb_mux.vhd
│   └── tb_mux2.vhd
└── README.md
```

### Coding conventions

- `std_logic_vector` at ports, `numeric_std` for arithmetic
- Architectures named `rtl` (behavioural), `structural` (instantiation only) or `sim` (testbenches)
- Synchronous active-high reset
- Instances prefixed `u_` in the top level
- Every combinational process assigns defaults before any branching, so no latches are inferred
- Every `case` on the opcode has a `when others` branch, so all 256 opcodes are covered
- FSM states as an enumerated type, so waveforms and failure messages show state names

---

## Running the simulation

1. Create a new RTL project in Vivado.
2. **Add design sources:** every file in `rtl/`.
3. **Add simulation sources:** every file in `tb/`.
4. **Compile order:** `cpu_pkg.vhd` must compile first (it is used by `alu`, `control_unit`, `instr_rom`, `cpu` and several testbenches). Right-click in Sources → **Hierarchy Update** → **Automatic Update and Compile Order**, then check the **Compile Order** tab.
5. Right-click the testbench to run → **Set as Top**.
6. **Run Simulation** → **Run Behavioral Simulation**.
7. Check the Tcl Console for `Note: all tests completed and passed`.

A failing run stops at the first failed check, naming the test and signal, for example:

```
Failure: cycle 58 failed: c_dbg
Failure: test 22 INC execute failed: c_load
Failure: test 4 LD writeback failed: state is S_FETCH
```

---

## Verification

Every testbench is self-checking (`assert ... severity failure`). The clocked FSM and system testbenches use a `check` procedure so each cycle is one line that compares every output.

### Testbenches

| Testbench | Checks | What is covered | Passes at |
|---|---|---|---|
| `tb_mux2` | 10 | Both select values over several bit patterns | 100 ns |
| `tb_wb_mux` | 6 | All four writeback paths | 60 ns |
| `tb_alu` | 32 | Every operation including SHL/SHR/INC/DEC, carry/borrow and wrap edge cases, spare codes | 320 ns |
| `tb_instr_rom` | 8 | Program words (including a new opcode) against hand-encoded 24-bit hex | 80 ns |
| `tb_data_ram` | 9 | Writes, top address, blocked write, write timing | 90 ns |
| `tb_pc` | 11 | Reset, increment, hold, load priority, wrap | 120 ns |
| `tb_ir` | 8 | Reset, load, hold, full 24-bit width, reset priority, load timing | 80 ns |
| `tb_flags_reg` | 9 | Independent flag loads, hold, reset priority, timing | 90 ns |
| `tb_reg_file` | 14 | Every register, both ports, reset priority, timing | 140 ns |
| `tb_control_unit` | 87 | Every opcode through its full state sequence; each conditional jump both ways; an unused opcode as NOP; reset mid-instruction | 870 ns |
| `tb_cpu` | 80 cycles | Full program, FSM state and all debug outputs every cycle | 800 ns |

In `tb_control_unit` the opcode changes only during FETCH, exactly as the IR would load it, so EXECUTE-to-next transitions are never tested with the wrong opcode. The unused-opcode test (`FF`) runs with both flags set, proving an unknown opcode can never trigger a jump.

`tb_instr_rom` deliberately compares against hand-written hex rather than `cpu_pkg` constants, so it independently checks the encoding.

### System test program

| Addr | Instruction | Hex | Effect |
|---|---|---|---|
| 0 | `LDI R0, 0F` | `01000F` | R0 = 0F |
| 1 | `LDI R1, 3C` | `01103C` | R1 = 3C |
| 2 | `MOV R2, R1` | `022100` | R2 = 3C |
| 3 | `ADD R2, R0` | `052000` | R2 = 4B |
| 4 | `AND R2, R1` | `072100` | R2 = 08 |
| 5 | `OR R2, R0` | `082000` | R2 = 0F |
| 6 | `XOR R2, R0` | `092000` | R2 = 00, Z = 1 |
| 7 | `JZ 09` | `0D0009` | Taken |
| 8 | `LDI R3, FF` | `0130FF` | Must be skipped |
| 9 | `NOT R2` | `0A2000` | R2 = FF |
| 10 | `ST R2, 20` | `042020` | RAM[20] = FF |
| 11 | `LD R3, 20` | `033020` | R3 = FF |
| 12 | `SUB R0, R1` | `060100` | R0 = D3, C = 1 (borrow) |
| 13 | `JC 0F` | `0F000F` | Taken |
| 14 | `LDI R3, 00` | `013000` | Must be skipped |
| 15 | `CMP R3, R2` | `0B3200` | Z = 1, C = 0, R3 unchanged |
| 16 | `JNZ 16` | `0E0016` | Not taken |
| 17 | `NOP` | `000000` | |
| 18 | `INC R2` | `122000` | R2 = 00 (FF wraps), Z = 1, C = 1 |
| 19 | `DEC R1` | `131000` | R1 = 3B, Z = 0, C = 0 |
| 20 | `SHL R0` | `100000` | R0 = A6, C = 1 (bit 7 out) |
| 21 | `SHR R0` | `110000` | R0 = 53, C = 0 (bit 0 out) |
| 22 | `JMP 16` | `0C0016` | Halt |

### Expected trace

Checked by `tb_cpu` at each falling edge. Values are hexadecimal.

How to read it:
- **PC runs one ahead after FETCH**: it increments in FETCH, so DECODE onwards shows the next address.
- **IR changes only at the end of FETCH**; cycle 0 shows `000000` from reset.
- **Results appear one state later**: a WRITEBACK's value is visible at the next FETCH; flags loaded in EXECUTE are visible from the next state.
- **The halt** cycles FETCH, DECODE, EXECUTE on `JMP 16`, so the PC alternates 16, 17, 17.

| Cycle | State | PC | IR | Instruction in IR | reg_a | Z | C |
|---|---|---|---|---|---|---|---|
| 0 | FETCH | 00 | `000000` | (reset) | 00 | 0 | 0 |
| 1 | DECODE | 01 | `01000F` | LDI R0, 0F | 00 | 0 | 0 |
| 2 | WRITEBACK | 01 | `01000F` | LDI R0, 0F | 00 | 0 | 0 |
| 3 | FETCH | 01 | `01000F` | LDI R0, 0F | 0F | 0 | 0 |
| 4 | DECODE | 02 | `01103C` | LDI R1, 3C | 00 | 0 | 0 |
| 5 | WRITEBACK | 02 | `01103C` | LDI R1, 3C | 00 | 0 | 0 |
| 6 | FETCH | 02 | `01103C` | LDI R1, 3C | 3C | 0 | 0 |
| 7 | DECODE | 03 | `022100` | MOV R2, R1 | 00 | 0 | 0 |
| 8 | WRITEBACK | 03 | `022100` | MOV R2, R1 | 00 | 0 | 0 |
| 9 | FETCH | 03 | `022100` | MOV R2, R1 | 3C | 0 | 0 |
| 10 | DECODE | 04 | `052000` | ADD R2, R0 | 3C | 0 | 0 |
| 11 | EXECUTE | 04 | `052000` | ADD R2, R0 | 3C | 0 | 0 |
| 12 | WRITEBACK | 04 | `052000` | ADD R2, R0 | 3C | 0 | 0 |
| 13 | FETCH | 04 | `052000` | ADD R2, R0 | 4B | 0 | 0 |
| 14 | DECODE | 05 | `072100` | AND R2, R1 | 4B | 0 | 0 |
| 15 | EXECUTE | 05 | `072100` | AND R2, R1 | 4B | 0 | 0 |
| 16 | WRITEBACK | 05 | `072100` | AND R2, R1 | 4B | 0 | 0 |
| 17 | FETCH | 05 | `072100` | AND R2, R1 | 08 | 0 | 0 |
| 18 | DECODE | 06 | `082000` | OR R2, R0 | 08 | 0 | 0 |
| 19 | EXECUTE | 06 | `082000` | OR R2, R0 | 08 | 0 | 0 |
| 20 | WRITEBACK | 06 | `082000` | OR R2, R0 | 08 | 0 | 0 |
| 21 | FETCH | 06 | `082000` | OR R2, R0 | 0F | 0 | 0 |
| 22 | DECODE | 07 | `092000` | XOR R2, R0 | 0F | 0 | 0 |
| 23 | EXECUTE | 07 | `092000` | XOR R2, R0 | 0F | 0 | 0 |
| 24 | WRITEBACK | 07 | `092000` | XOR R2, R0 | 0F | 1 | 0 |
| 25 | FETCH | 07 | `092000` | XOR R2, R0 | 00 | 1 | 0 |
| 26 | DECODE | 08 | `0D0009` | JZ 09 | 0F | 1 | 0 |
| 27 | EXECUTE | 08 | `0D0009` | JZ 09 | 0F | 1 | 0 |
| 28 | FETCH | 09 | `0D0009` | JZ 09 | 0F | 1 | 0 |
| 29 | DECODE | 0A | `0A2000` | NOT R2 | 00 | 1 | 0 |
| 30 | EXECUTE | 0A | `0A2000` | NOT R2 | 00 | 1 | 0 |
| 31 | WRITEBACK | 0A | `0A2000` | NOT R2 | 00 | 0 | 0 |
| 32 | FETCH | 0A | `0A2000` | NOT R2 | FF | 0 | 0 |
| 33 | DECODE | 0B | `042020` | ST R2, 20 | FF | 0 | 0 |
| 34 | EXECUTE | 0B | `042020` | ST R2, 20 | FF | 0 | 0 |
| 35 | FETCH | 0B | `042020` | ST R2, 20 | FF | 0 | 0 |
| 36 | DECODE | 0C | `033020` | LD R3, 20 | 00 | 0 | 0 |
| 37 | EXECUTE | 0C | `033020` | LD R3, 20 | 00 | 0 | 0 |
| 38 | WRITEBACK | 0C | `033020` | LD R3, 20 | 00 | 0 | 0 |
| 39 | FETCH | 0C | `033020` | LD R3, 20 | FF | 0 | 0 |
| 40 | DECODE | 0D | `060100` | SUB R0, R1 | 0F | 0 | 0 |
| 41 | EXECUTE | 0D | `060100` | SUB R0, R1 | 0F | 0 | 0 |
| 42 | WRITEBACK | 0D | `060100` | SUB R0, R1 | 0F | 0 | 1 |
| 43 | FETCH | 0D | `060100` | SUB R0, R1 | D3 | 0 | 1 |
| 44 | DECODE | 0E | `0F000F` | JC 0F | D3 | 0 | 1 |
| 45 | EXECUTE | 0E | `0F000F` | JC 0F | D3 | 0 | 1 |
| 46 | FETCH | 0F | `0F000F` | JC 0F | D3 | 0 | 1 |
| 47 | DECODE | 10 | `0B3200` | CMP R3, R2 | FF | 0 | 1 |
| 48 | EXECUTE | 10 | `0B3200` | CMP R3, R2 | FF | 0 | 1 |
| 49 | FETCH | 10 | `0B3200` | CMP R3, R2 | FF | 1 | 0 |
| 50 | DECODE | 11 | `0E0016` | JNZ 16 | D3 | 1 | 0 |
| 51 | EXECUTE | 11 | `0E0016` | JNZ 16 | D3 | 1 | 0 |
| 52 | FETCH | 11 | `0E0016` | JNZ 16 | D3 | 1 | 0 |
| 53 | DECODE | 12 | `000000` | NOP | D3 | 1 | 0 |
| 54 | EXECUTE | 12 | `000000` | NOP | D3 | 1 | 0 |
| 55 | FETCH | 12 | `000000` | NOP | D3 | 1 | 0 |
| 56 | DECODE | 13 | `122000` | INC R2 | FF | 1 | 0 |
| 57 | EXECUTE | 13 | `122000` | INC R2 | FF | 1 | 0 |
| 58 | WRITEBACK | 13 | `122000` | INC R2 | FF | 1 | 1 |
| 59 | FETCH | 13 | `122000` | INC R2 | 00 | 1 | 1 |
| 60 | DECODE | 14 | `131000` | DEC R1 | 3C | 1 | 1 |
| 61 | EXECUTE | 14 | `131000` | DEC R1 | 3C | 1 | 1 |
| 62 | WRITEBACK | 14 | `131000` | DEC R1 | 3C | 0 | 0 |
| 63 | FETCH | 14 | `131000` | DEC R1 | 3B | 0 | 0 |
| 64 | DECODE | 15 | `100000` | SHL R0 | D3 | 0 | 0 |
| 65 | EXECUTE | 15 | `100000` | SHL R0 | D3 | 0 | 0 |
| 66 | WRITEBACK | 15 | `100000` | SHL R0 | D3 | 0 | 1 |
| 67 | FETCH | 15 | `100000` | SHL R0 | A6 | 0 | 1 |
| 68 | DECODE | 16 | `110000` | SHR R0 | A6 | 0 | 1 |
| 69 | EXECUTE | 16 | `110000` | SHR R0 | A6 | 0 | 1 |
| 70 | WRITEBACK | 16 | `110000` | SHR R0 | A6 | 0 | 0 |
| 71 | FETCH | 16 | `110000` | SHR R0 | 53 | 0 | 0 |
| 72 | DECODE | 17 | `0C0016` | JMP 16 | 53 | 0 | 0 |
| 73 | EXECUTE | 17 | `0C0016` | JMP 16 | 53 | 0 | 0 |
| 74 | FETCH | 16 | `0C0016` | JMP 16 | 53 | 0 | 0 |
| 75 | DECODE | 17 | `0C0016` | JMP 16 | 53 | 0 | 0 |
| 76 | EXECUTE | 17 | `0C0016` | JMP 16 | 53 | 0 | 0 |
| 77 | FETCH | 16 | `0C0016` | JMP 16 | 53 | 0 | 0 |
| 78 | DECODE | 17 | `0C0016` | JMP 16 | 53 | 0 | 0 |
| 79 | EXECUTE | 17 | `0C0016` | JMP 16 | 53 | 0 | 0 |

Key checks: register results at the FETCH after each WRITEBACK (cycles 3, 6, 9, 13...), the jumps landing at 09 (cycle 28) and 0F (cycle 46), R3 still 00 at cycle 36 (the skipped LDI never ran) and FF at cycle 47 (LD worked), JNZ falling through to 11 (cycle 52), INC wrapping FF to 00 with Z and C set (cycles 58-59), DEC clearing both flags (cycle 62), SHL moving bit 7 into C (cycles 66-67), SHR clearing C (cycles 70-71), and the halt loop from cycle 72.

---

## Writing your own program

Programs live in the `rom_data` constant in `instr_rom.vhd`, built from `cpu_pkg` constants as `opcode & rd & rs & imm`:

```vhdl
constant rom_data : rom_type := (
    0 => OP_LDI & REG0 & REG0 & x"05",   -- LDI R0, 05   counter
    1 => OP_DEC & REG0 & REG0 & x"00",   -- DEC R0
    2 => OP_JNZ & REG0 & REG0 & x"01",   -- JNZ 01       loop until R0 = 0
    3 => OP_JMP & REG0 & REG0 & x"03",   -- JMP 03       halt
    others => x"000000"
);
```

- Put `REG0` and `x"00"` in unused fields.
- Jump targets in `imm` are hexadecimal; array indices on the left are decimal.
- End with a `JMP` to its own address.
- After changing the program, update `tb_instr_rom.vhd` and the expected trace in `tb_cpu.vhd`. Remember each instruction takes 3 or 4 cycles.

### Adding an instruction

1. Add an `OP_*` constant in `cpu_pkg` (next free opcode: `14`) and, if it needs a new ALU operation, an `ALU_*` constant (next free code: `1010`).
2. Add the operation to the `case` in `alu.vhd`.
3. In `control_unit.vhd`: add it to the EXECUTE → WRITEBACK list if it writes a register, add its `alu_sel`/`wb_sel`, and add it to the right flag-load line.
4. Add tests to `tb_alu` and `tb_control_unit`, and use it in the program.

---

## Limitations

- No stack, subroutine calls or interrupts.
- No rotate or arithmetic-shift instructions; shifts are one bit at a time.
- Only direct addressing for LD/ST.
- Unsigned arithmetic only: no overflow or negative flag.
- Only 4 registers, although the instruction format has room for 16.
- The program is fixed in `instr_rom.vhd`.
- Memories still read asynchronously. FPGA block RAM reads are synchronous; supporting them needs an extra state or holding registers.

---

## Future work

- **Synchronous memories** (block-RAM style), with A/B/ALUOut holding registers.
- **Shared instruction/data memory** (von Neumann), which the multi-cycle structure makes possible.
- **Load the ROM from a text file** at simulation start.
- **Rotate instructions** (ROL/ROR through carry), using spare ALU codes `1010`-`1111`.
- **More registers**, using the reserved upper bits of the rd and rs fields.
- **Stack pointer** with PUSH, POP, CALL and RET.
