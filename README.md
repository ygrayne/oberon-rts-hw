# Oberon RTS Hardware

**Experimental work in progress!**

## Introduction

The purpose of the contents of this repo is to develop and provide hardware platforms for embedded Oberon systems, either Embedded Project Oberon, or Oberon RTS.

Here is the sister repo for the corresponding software: [oberon-rts-sw](https://github.com/ygrayne/oberon-rts-sw).

Check out [oberon-rts.org](https://oberon-rts.org), which is awfully behind, but it's the best there is for now, apart from this and the corresponding software repository. As the saying goes, only debug code, don't get deceived by the comments.


## Current Status

* 2023-04-09: extended the system control and status register for the new error handling.

* 2023-04-05: (re-) implemented the watchdog and the stack overflow monitor. Their error signals result in an error handling that is unified together with the trap handling.

* 2023-03-29:: two platforms, P3 and P4, each implement the same functionality needed to run a simplified version of Oberon RTS (Embedded Project Oberon software runs as well, out of the box). These two platforms shall serve as basis for all work going forward.

* 2023-03-30: Added log buffer

Most on-chip devices, such as process timers, reset circuits, or SPI and RS232 interfaces, can now directly be (and are) used by either architecture without adaptations or specific configurations.


## Next Up

* Rethink processes and their control and monitoring elements in the hardware.


## Architectures

There are two different architectures for the RISC5 CPU and its environment:

* ETH: as defined and implemented by
  * [Project Oberon](http://projectoberon.net) (Niklaus Wirth)
  * [Embedded Project Oberon](https://astrobe.com/RISC5/ReadMe.htm) (Chris Burrows)
* THM: as defined and implemented by
  * [THM architecture](https://github.com/hgeisse/THM-Oberon) (Hellwig Geisse)

As used, implemented and extended here, both architectures are to be used with the Oberon cross compiler by Astrobe for RISC5.

Basis:
* ETH: Embedded Project Oberon v8.0
* THM: the THM variant was forked from an older commit and status, as I have run into issues with the latest version. Specifically, the handling (or even existence?) of the H special register has tripped the software generated with the Astrobe compiler. I have not fully investigated this yet.


## Platforms

A platform is based on:
* a specific FPGA board
* an implementation of the RISC5 CPU on that FPGA
* a set of peripherals and devices on that FPGA
* allocation of connections between the FPGA and the electronic devices and connectors on the board

consequently, a programming model, including
* a CPU and its instruction set (as of now, the RISC5 cpu)
* RAM and PROM memory map,
* device IO memory map,
* device functionality (IO devices and others on the FPGA),
etc., ie. the basis for specific embedded Oberon systems.

A platform is denoted as follows, for example:
* p1-eth-arty-a7-100
* p2-thm-de2-115


## Technologies

Two FPGA technologies are used:
* Xilinx Artix-7
* Altera Cyclone IV and Cyclone V

Tools:
* for Xilinx FPGA: Vivado
* for Altera FPGA: Quartus


## Boards

* Digilent Arty A7-100 (Artix-7), "arty-a7-100"
* Terasic DE2-115 (Cyclone IV), "de2-115"
* Digilent Nexys Video (Artix-7), "nexys-a7-100"
* Terasic Cyclone V GX Starter Kit (Cyclone V), "cvgx-sk"

The focus is currently on the Arty and the DE2-115.


## Directory Structure

Note: these directories may or may not be visible in the repo, as some are still empty, or just placeholders for the structure's sake.

* lib
  * eth: Verilog modules for ETH architecture (see remarks below)
    * cpu
    * base: basic functionality
    * ext: extended functionality
    * io: well, IO, eg. RS232, GPI, SPI
    * mon: system monitoring and instrumention
    * gen: general functionality, eg. fifos, stacks
  * thm: Verilog modules for THM architecture
    * (as for eth)
  * any: modules for both architectures
    * (as for eth)
  * board: board-specific modules
    * eth
      * arty-a7-100
        * eg. board specific IO, such as for LEDs and switches
      * cvgx-sk
      * de2-115
      * nexys-a7-200
    * thm
      * (as for eth)
  * tech: technology-specific modules
    * eth
      * artix-7
        * eg. for clocks
      * cyclone-iv
      * cyclone-v
    * thm
      * (as for eth)
* platform:
  * p3-thm-de2-115
    * risc5.v (top Verilog file)
    * risc5.sdc (constraints)
    * build: Quartus project directory
      * risc5.qsf (project settings, pin allocations, list of Verilog design files)
      * risc5.qpf (project file for Quartus)
    * promfiles: PROM load files, incl. Oberon source
  * p4-eth-arty-a7-100
    * RISC5Top.v (top Verilog file)
    * arty-a7.xdc (constraints, includes pin allocations)
    * build: Vivado project directory
      * p4-eth-arty-a7-100.xpr (project file for Vivado, list of Verilog design files)
    * promfiles: PROM load files, incl. Oberon source
* orig: the original modules
  * epo: Embedded Project Oberon (which uses ETH architecture)
  * thm: THM-Oberon
* epo-base: all libs and build directories to build the two base platforms for EPO using ETH and THM architectures
  * lib (see above)
    * eth
    * thm
    * board
    * tech
  * platform
    * p1-eth-arty-a7-100: EPO on ETH architecture
    * p2-thm-de2-115: EPO on THM architecture

With directories
* 'cpu' and 'base' a processor can be constructed for EPO
  * eg. CPU, RAM, clock, reset
* 'ext' in addition, a processor can be constructed for Oberon RTS
  * eg. process timing, stack monitoring, error handling
* 'mon' in addition, the processor for RTS can be instrumented for monitoring
  * logging, process performance monitoring, calltracing


## Specific Platforms

See the README file in the platform directory.

* In epo-base
  * p1-eth-arty-a7-100: runs EPO 8.0 out-of-the-box
  * p2-thm-de-115: same as P1
* In main platform dir
  * p3-thm-de-115: runs minimal version of Oberon RTS (as well as EPO)
  * p4-eth-arty-a7-100: same as P3

"Same" means the SD card can be swapped.


## Licences and Copyright

The repo contains unaltered original files, as well as altered ones to implement adaptations and extensions. All files that were edited refer to their base and origin. The respective copyrights apply.

Please refer to COPYRIGHT.