# Oberon RTS Hardware

**Experimental work in progress!**

## Introduction

The purpose of the contents of this repo is to develop and provide hardware platforms for embedded Oberon systems, either Embedded Project Oberon, or Oberon RTS.

Here is the sister repo for the corresponding software: [oberon-rts-sw](https://github.com/ygrayne/oberon-rts-sw).

Check out [oberon-rts.org](https://oberon-rts.org), which is awfully behind, but it's the best there is for now, apart from this and the corresponding software repository. As the saying goes, only debug code, don't get deceived by the comments.


## Status

* two architectures: ETH and THM
* CPU, PROM, RAM
* clocks, reset
* process timers
* millisecond timer
* RS232 (buffered)
* SPI
* I2C
* LEDs, switches, buttons, 7-seg displays (if available)
* GPIO
* Reatl-time clock
* logging
* watchdog
* stack monitor
* system control and status
* calltrace
* (re-) start tables


## Next Up

* SRAM integration
* Hardware-signal based process scheduling.
* Hardware support for critical region protection for processes.


## Architectures

There are two different architectures for the RISC5 CPU and its environment:

* ETH: as defined and implemented by
  * [Project Oberon](http://projectoberon.net) (Niklaus Wirth)
  * [Embedded Project Oberon](https://astrobe.com/RISC5/ReadMe.htm) (Chris Burrows)
* THM: as defined and implemented by
  * [THM Oberon](https://github.com/hgeisse/THM-Oberon) (Hellwig Geisse)

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
* Terasic Cyclone V GX Starter Kit (Cyclone V), "cv-sk"


## Directory Structure

Note: these directories may or may not be visible in the repo, as some are still empty, or just placeholders for the structure's sake.

* lib
  * any: modules for both architectures
  * eth: Verilog modules for ETH architecture
  * thm: Verilog modules for THM architecture
  * board: board-specific modules
* platform:
  * p3-thm-de2-115
    * lib: platform specific modules, eg.
      * risc5.v (top Verilog file)
      * risc5.sdc (constraints)
      * clocks
    * build: Quartus project directory
      * risc5.qsf (project settings, pin allocations, list of Verilog design files)
      * risc5.qpf (project file for Quartus)
    * bootload: PROM load files, incl. Oberon source
  * p4-eth-arty-a7-100
    * lib
      * RISC5Top.v (top Verilog file)
      * arty-a7.xdc (constraints, includes pin allocations)
    * build: Vivado project directory
      * p4-eth-arty-a7-100.xpr (project file for Vivado, list of Verilog design files)
    * bootload
  * p5-eth-de2-115
  * p6-eth-cv-sk
* base: the original modules
  * epo: Embedded Project Oberon (which uses ETH architecture)
  * thm: THM-Oberon
* epo-base: all libs and build directories to build the two base platforms for EPO using ETH and THM architectures
  * lib (see above)
  * platform
    * p1-eth-arty-a7-100: EPO on ETH architecture
    * p2-thm-de2-115: EPO on THM architecture


## Licences and Copyright

The repo contains unaltered original files, as well as altered ones to implement adaptations and extensions. All files that were edited refer to their base and origin. The respective copyrights apply.

Please refer to COPYRIGHT.