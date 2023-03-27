## Constraints file for the Digilent ARTY A7-100T Rev. E
##
## Embedded Project Oberon OS
## Astrobe for RISC5 v7.0.2
## CFB Software
## http://www.astrobe.com
##
## CFB 21.12.2015 Initial Arty A7 Version
## CFB 29.02.2016 Reassigned SPI pins and added PULLUPs for MISO
## CFB 03.03.2016 Added switches and buttons
## CFB 24.07.2016 Removed generated clock
## CFB 21.06.2019 Arduino configuration, I2C, SPIx3, GPIOx32
## CFB 03.08.2019 Removed RGB LEDs
## CFB 27.05.2020 ARTY S7-100T


## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK100M]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK100M]


## Switches
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33}  [get_ports {swi[0]}]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {swi[1]}]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {swi[2]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {swi[3]}]


##Green LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33}  [get_ports {leds[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33}  [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33}  [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {leds[3]}]


##Buttons
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]


##Pmod Header JA
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {SS[0]}   ]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {MOSI[0]} ]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {MISO[0]} ]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {SCLK[0]} ]
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {GPIO[16]}]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {GPIO[17]}]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {GPIO[18]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {GPIO[19]}]
set_property PULLUP true [get_ports {MISO[0]}]


##Pmod Header JB
set_property -dict { PACKAGE_PIN E15 IOSTANDARD LVCMOS33 } [get_ports {SS[1]}]
set_property -dict { PACKAGE_PIN E16 IOSTANDARD LVCMOS33 } [get_ports {MOSI[1]}]
set_property -dict { PACKAGE_PIN D15 IOSTANDARD LVCMOS33 } [get_ports {MISO[1]}]
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports {SCLK[1]}]
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {GPIO[20]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {GPIO[21]}]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports {GPIO[22]}]
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports {GPIO[23]}]
set_property PULLUP true [get_ports {MISO[1]}]


##Pmod Header JC
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports {GPIO[24]}]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports {GPIO[25]}]
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports {GPIO[26]}]
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports {GPIO[27]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {GPIO[28]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {GPIO[29]}]
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports {GPIO[30]}]
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports {GPIO[31]}]


##USB-UART Interface
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports { TxD }]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33}  [get_ports { RxD }]


##ChipKit Digital I/O Low
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {GPIO[0]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {GPIO[1]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {GPIO[2]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {GPIO[3]}]
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports {GPIO[4]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {GPIO[5]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {GPIO[6]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {GPIO[7]}]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {GPIO[8]}]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {GPIO[9]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {SS[2]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {MOSI[2]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {MISO[2]}]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports {SCLK[2]}]
set_property PULLUP true [get_ports {MISO[2]}]


##ChipKit Digital I/O On Outer Analog Header
##NOTE: These pins should be used when using the analog header signals A0-A5 as digital I/O (Chipkit digital pins 14-19)
set_property -dict {PACKAGE_PIN F5 IOSTANDARD LVCMOS33} [get_ports {GPIO[10]}]
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports {GPIO[11]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {GPIO[12]}]
set_property -dict {PACKAGE_PIN E7 IOSTANDARD LVCMOS33} [get_ports {GPIO[13]}]
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports {GPIO[14]}]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {GPIO[15]}]


## ChipKit I2C
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { SCL }]
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { SDA }]


set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
