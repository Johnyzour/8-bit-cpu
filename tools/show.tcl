# File        : show.tcl
# Description : Vivado simulator (XSIM) script for tb_run. Runs the loaded
#               program to its halt loop, then prints R0-R3, the data area
#               F0-FF and the stack area E0-EF.
# Usage       : with tb_run as the simulation top, in the Tcl console:
#                   source <path to repo>/tools/show.tcl
# Notes       : Only reads simulation values; changes nothing.

run all

# Turns an XSIM array value into a plain list of hex bytes
proc to_bytes {raw} {
    return [string map {"," " " "\{" "" "\}" "" "\[" "" "\]" "" "\"" ""} $raw]
}

set regs [to_bytes [get_value -radix hex /tb_run/uut/u_reg_file/regs]]
set mem  [to_bytes [get_value -radix hex /tb_run/uut/u_memory/mem]]

puts ""
puts "R0-R3 : $regs"

if {[llength $mem] == 256} {
    puts "        +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F"
    puts "MEM F0: [lrange $mem 240 255]"
    puts "MEM E0: [lrange $mem 224 239]"
} else {
    puts "MEM   : $mem"
}
