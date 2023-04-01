## Constraints file for p4-eth-arty-a7-100
## Stripped down
## --
## Based on Embedded Oberon, Astrobe for RISC5 v7.0.2
## CFB Software
## http://www.astrobe.com

## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_in]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_in]

#set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33}  [get_ports {reset}]

## Switches
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33}  [get_ports {swi_in[0]}]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {swi_in[1]}]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {swi_in[2]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {swi_in[3]}]

## Buttons
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports {btn_in[0]}]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {btn_in[1]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports {btn_in[2]}]
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports {btn_in[3]}]

## Green LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33}  [get_ports {led_g[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33}  [get_ports {led_g[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33}  [get_ports {led_g[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {led_g[3]}]

## RGB LEDs
#set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[2]}]; # RGB LED 0, blue
#set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[1]}]; # RGB LED 0, green
#set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[0]}]; # RGB LED 0, red
#set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[5]}]; # RGB LED 1, blue
#set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[4]}]; # RGB LED 1, green
#set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[3]}]; # RGB LED 1, red
#set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[8]}]; # RGB LED 2, blue
#set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[7]}]; # RGB LED 2, green
#set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[6]}]; # RGB LED 2, red
#set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[11]}]; # RGB LED 3, blue
#set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[10]}]; # RGB LED 3, green
#set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports {rgbLeds[9]}]; # RGB LED 3, red


## Pmod Header JA
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {sdcard_cs_n}]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {sdcard_mosi}]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {sdcard_miso}]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {sdcard_sclk}]
#set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {GPIO[12]}]
#set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {GPIO[13]}]
#set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {GPIO[14]}]
#set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {GPIO[15]}]
#set_property PULLUP true [get_ports {spi_0_miso[0]}]

## Pmod Header JB
#set_property -dict { PACKAGE_PIN E15 IOSTANDARD LVCMOS33 } [get_ports {spi2_CS[0]}]
#set_property -dict { PACKAGE_PIN E16 IOSTANDARD LVCMOS33 } [get_ports {spi2_MOSI}]
#set_property -dict { PACKAGE_PIN D15 IOSTANDARD LVCMOS33 } [get_ports {spi2_MISO}]
#set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports {spi2_SCLK}]
#set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {spi2_CS[1]}]
#set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {spi2_CTRL}]
#set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports {GPIO[8]}]
#set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports {GPIO[9]}]
#set_property PULLUP true [get_ports {spi2_MISO}]

## Pmod Header JC
#set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports {spi3_CS}]
#set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports {spi3_MOSI}]
#set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports {spi3_MISO}]
#set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports {spi3_SCLK}]
#set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {GPIO[24]}]
#set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {spi3_CTRL}]
#set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports {GPIO[10]}]
#set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {GPIO[11]}]
#set_property PULLUP true [get_ports {spi3_MISO}]

## Pmod Header JD: system leds
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[0]}]; # pin1: top row, first right from front
set_property -dict { PACKAGE_PIN D3 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[1]}]; #
set_property -dict { PACKAGE_PIN F4 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[2]}]; #
set_property -dict { PACKAGE_PIN F3 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[3]}]; #
set_property -dict { PACKAGE_PIN E2 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[4]}]; # pin4: bottom row, first right from front
set_property -dict { PACKAGE_PIN D2 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[5]}]; #
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[6]}]; #
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports {sys_leds[7]}]; #

## USB-UART Interface (Astrobe console)
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports {rs232_0_txd}]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33}  [get_ports {rs232_0_rxd}]

## Header J4
## Outer header row towards Pmod headers (Chipkit IO0 to IO7)
#set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {GPIO[0]}] ; # IO0
#set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {GPIO[1]}]
#set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {GPIO[2]}]
#set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {GPIO[3]}]
#set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports {GPIO[4]}]
#set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {GPIO[5]}]
#set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {GPIO[6]}]
#set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {GPIO[7]}] ; # IO7

# Inner header row (Chipkit IO26 to IO33)
#set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports {extp[7]}]; # IO26
#set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {extp[6]}]
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports {extp[5]}]
#set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports {extp[4]}]
#set_property -dict { PACKAGE_PIN R11   IOSTANDARD LVCMOS33 } [get_ports {extp[3]}]
#set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports {extp[2]}]
#set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports {extp[1]}]
#set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports {extp[0]}]; # IO33

## Header J3 (Chipkit IO8 to IO13, Gnd, A, SDA, SCL)
#set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {GPIO[8]}] ; # I08
#set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {GPIO[9]}] ; # IO9
#set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {spi_0_cs_n[1]}]   ; # IO10
#set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {spi_0_mosi[1]}]
#set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {spi_0_miso[1]}]
#set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports {spi_0_sclk[1]}] ; # IO13
#set_property PULLUP true [get_ports {spi_0_miso[1]}]

#set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {i2c_SCL}]
#set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {i2c_SDA}]

### Header J2 (Chipkit IO34 to IO41)
#set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports {rs2323_txD}];    # IO34
#set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports {rs2323_rxD}]
#set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports {rs2322_txD}]
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports {rs2322_rxD}]

set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports {spi_0_cs_n[1]}] ; # IO38
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {spi_0_mosi[1]}]
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports {spi_0_miso[1]}]
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports {spi_0_sclk[1]}]; # IO41
set_property PULLUP true [get_ports {spi_0_miso[1]}]


## ChipKit Digital I/O On Outer Analog Header
## NOTE: These pins should be used when using the analog header signals A0-A5 as digital I/O (Chipkit digital pins 14-19)
#set_property -dict {PACKAGE_PIN F5 IOSTANDARD LVCMOS33} [get_ports {GPIO[10]}]
#set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports {GPIO[11]}]
#set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {GPIO[12]}]
#set_property -dict {PACKAGE_PIN E7 IOSTANDARD LVCMOS33} [get_ports {GPIO[13]}]
#set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports {GPIO[14]}]
#set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {GPIO[15]}]



set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]


## Quad SPI Flash
#set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
#set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]

## Power Measurements
#set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33     } [get_ports { vsnsvu_n }]; #IO_L7N_T1_AD2N_15 Sch=ad_n[2]
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33     } [get_ports { vsnsvu_p }]; #IO_L7P_T1_AD2P_15 Sch=ad_p[2]
#set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33     } [get_ports { vsns5v0_n }]; #IO_L3N_T0_DQS_AD1N_15 Sch=ad_n[1]
#set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33     } [get_ports { vsns5v0_p }]; #IO_L3P_T0_DQS_AD1P_15 Sch=ad_p[1]
#set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33     } [get_ports { isns5v0_n }]; #IO_L5N_T0_AD9N_15 Sch=ad_n[9]
#set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33     } [get_ports { isns5v0_p }]; #IO_L5P_T0_AD9P_15 Sch=ad_p[9]
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33     } [get_ports { isns0v95_n }]; #IO_L8N_T1_AD10N_15 Sch=ad_n[10]
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33     } [get_ports { isns0v95_p }]; #IO_L8P_T1_AD10P_15 Sch=ad_p[10]

## Constraints file for the Digilent ARTY A7-35T Rev. C
##
## Embedded Project Oberon OS
## Astrobe for RISC5 v7.0.2
## CFB Software
## http://www.astrobe.com
##
## CFB 21.12.2015 Initial Version
## CFB 29.02.2016 Reassigned SPI pins and added PULLUPs for MISO
## CFB 03.03.2016 Added switches and buttons
## CFB 24.07.2016 Removed generated clock
## CFB 21.06.2019 Arduino configuration, I2C, SPIx3, GPIOx32
## CFB 03.08.2019 Removed RGB LEDs