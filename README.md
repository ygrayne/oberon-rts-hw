# Oberon RTS Hardware

**Work in progress!**

## Introduction

The purpose of this repo is to develop and provide hardware platforms for embedded Oberon systems, either Embedded Project Oberon, or Oberon RTS.

There is (or will be shortly) another repo for the corresponding software, oberon-rts-sw.

## Overview

There are two different architectures:
* ETH: as defined and implemented by
  * Project Oberon (N. Wirth)
  * Embedded Project Oberon (Chris Burrows)
* THM: as defined and implemented by
  * THM-Oberon (Hellwig Geisse)

As used, implemented and extended here, both architectures are to be used with the Oberon compiler by Astrobe for RISC5.

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

* oberon-rts-hw
  * lib
    * eth: Verilog modules for ETH architecture
    * thm: Verilog modules for THM architecture
    * gen: generic modules for both architectures
    * board: board-specific modules
      * eth
        * arty-a7-100
        * cvgx-sk
        * de2-115
        * nexys-a7-200
      * thm
        * (as for eth)
    * tech: technology-specific modules
      * eth
        * artix-7: Xilinx
        * cyclone-iv: Altera
        * cyclone-v: Altera
      * thm
        * (as for eth)
  * platform: for example:
    * p1-eth-arty-a7-100
      * RISC5Top.v (top Verilog file)
      * ArtyA7-100.xdc (constraints, includes pin allocations)
      * build: Vivado project directory
        * p1-eth-arty-a7-100.xpr (project file for Vivado, list of Verilog design files)
      * memfiles: PROM load files, incl. Oberon source
    * p2-thm-de2-115
      * risc5.v (top Verilog file)
      * risc5.sdc (constraints)
      * build: Quartus project directory
        * risc5.qsf (project settings, pin allocations, list of Verilog design files)
        * risc5.qpf (project file for Quartus)
      * promfiles: PROM load files, incl. Oberon source
  * orig: the original modules
    * epo: Embedded Project Oberon (which uses ETH architecture)
    * thm: THM-Oberon

## Platforms

See the README file in the platform directory.

* p1-eth-arty-a7-100: runs EPO 8.0 out-of-the-box
* p2-thm-de-115: runs EPO 8.0 out-of-the-box


## Licences

All files that were edited refer to their base. The respective copyrights apply.

Please refer to COPYRIGHT.
