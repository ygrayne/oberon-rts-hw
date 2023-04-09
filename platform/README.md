# Platforms

## Status

There are two platforms with the required functionality to support a simplified version of Oberon RTS (as well as EPO), while bringing back the basic functionality.

* p3-eth-arty-a7-100
* p4-thm-de2-115

Support the same version of Oberon RTS, ie. swapping the SD card is possible. Some LEDs and switches are missing on the Arty A7 board, compared to the DE2-115, so, unsurprisingly, they won't work. But the software should not choke up about them, and uses only the elements that are available on either board for necessary indicators and input buttons and switches.
