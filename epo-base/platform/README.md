# Platforms

## p1-eth-arty-a7-100

*Board:* Digilent Arty-A7-100

*FPGA:* Xilinx Artix-7-100

*Toolchain:* Vivado


Supports: Embedded Project Oberon v8.0.
The disk image as provided with Astrobe for RISC5 v8.0 can be used out of the box.

No changes were made to the Verilog code. You need to generate the 'prom.mem' file with 'BootLoad.mod' in the platform's 'promfiles' directory, and place it one level up of the 'PROM.v' file.


## p2-thm-de2-115

*Board:* Terasic DE2-115

*FPGA:* Altera Cyclone IV

*Toolchain:* Quartus

Supports: Embedded Project Oberon v8.0, with 16 MB of RAM.
The disk image as provided with Astrobe for RISC5 v8.0 can be used out of the box.

You need to generate the 'BootLoad-16M-8M.mem' file with 'BootLoad.mod' in the platform's 'promfiles' directory, and leave it in this directory.
