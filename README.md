# 8-bit CPU in VHDL — Von Neumann version

An 8-bit, multi-cycle CPU written in VHDL, being converted from a Harvard
architecture to a **von Neumann architecture**: one shared memory that holds
both the program and the data.

This branch starts from the multi-cycle CPU on `multicycle`. That design has a
separate instruction ROM and data RAM. Here they are replaced by a single
memory, with the FSM control unit taking turns between fetching instructions
and reading or writing data.

**Status:** Work in progress.

> **Branches**
>
> | Branch | Version | Status |
> |---|---|---|
> | `main` | Single-cycle CPU, 16-bit instructions (tag `v1.0-single-cycle`) | Complete and verified |
> | `multicycle` | Multi-cycle CPU with an FSM control unit, 24-bit instructions, 20 instructions | Complete and verified |
> | `von-neumann` | Multi-cycle CPU with a shared instruction/data memory | In progress (this branch) |
>
> Each branch is a separate stage of the project and is kept as it is. This branch will not be merged into `main`.

---

## Harvard vs von Neumann

| | Harvard (`multicycle`) | Von Neumann (this branch) |
|---|---|---|
| Memories | Separate instruction ROM and data RAM | One shared memory |
| Fetch and data access | Can happen at the same time | Share one memory port, so they happen in different FSM states |
| Self-modifying code | Impossible: a program cannot write its own code | Possible: instructions are ordinary memory contents |

## Planned changes

- [ ] Replace `instr_rom` and `data_ram` with a single memory
- [ ] Add a memory address multiplexer: PC during FETCH, `imm` during LD/ST
- [ ] Update the control FSM so FETCH and data accesses never use the memory in the same state
- [ ] Load the program and data into the shared memory at reset
- [ ] Update the component and system testbenches, including the expected trace

## Running the simulation

Same as the `multicycle` branch: add `rtl/` as design sources and `tb/` as
simulation sources in Vivado, make sure `cpu_pkg.vhd` compiles first, set a
testbench as top and run a behavioral simulation.
