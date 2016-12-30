EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:picoPOKER-cache
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 4
Title "picoPOKER Keyboard"
Date "2000-12-31"
Rev "-"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Sheet
S 4100 1700 1200 3800
U 570C4CA9
F0 "MCU" 60
F1 "mcu.sch" 60
F2 "~KEY_INT" B R 5300 4500 60 
F3 "KEY_ROWS" O R 5300 4700 60 
F4 "KEY_COLS" B R 5300 4900 60 
F5 "BLE_PWR_EN" O R 5300 2950 60 
F6 "~RESET" I R 5300 2400 60 
F7 "VBAT_SENSE" I R 5300 2750 60 
F8 "VBAT_SENSE_EN" O R 5300 2600 60 
F9 "CAPS_LED_EN" O R 5300 5100 60 
$EndSheet
$Sheet
S 6100 4150 1100 1150
U 570CA3AA
F0 "Matrix" 60
F1 "matrix.sch" 60
F2 "~KEY_INT" B L 6100 4500 60 
F3 "KEY_ROWS" I L 6100 4700 60 
F4 "KEY_COL" B L 6100 4900 60 
F5 "CAPS_LED_EN" I L 6100 5100 60 
$EndSheet
$Sheet
S 6100 1850 1050 1600
U 5715D81C
F0 "Power" 60
F1 "power.sch" 60
F2 "~RESET" O L 6100 2400 60 
F3 "BLE_PWR_EN" I L 6100 2950 60 
F4 "VBAT_SENSE_EN" I L 6100 2600 60 
F5 "VBAT_SENSE" O L 6100 2750 60 
$EndSheet
Wire Wire Line
	5300 2950 6100 2950
Wire Wire Line
	5300 2400 6100 2400
Wire Wire Line
	5300 2600 6100 2600
Wire Wire Line
	5300 2750 6100 2750
Wire Wire Line
	5300 4500 6100 4500
Wire Bus Line
	5300 4700 6100 4700
Wire Bus Line
	5300 4900 6100 4900
Wire Wire Line
	5300 5100 6100 5100
$EndSCHEMATC
