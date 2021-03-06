MCU Trade Study Analysis
========================

NOTE:  This analysis may not be kept up-to-date with the latest design decisions.  This analysis was performed only for the initial selection.

Purpose
-------
The purpose of this analysis is to determine the appropriate MCU choice for the picoPOKER platform.

However, this project has already decided on the Atmel AVR series of microcontrollers due to:  
* existing community support in other keyboard projects
  * [tmk\_core](https://github.com/tmk/tmk_core)
  * [qmk\_firmware](qmk.fm)
* accessability of development tools
* a sufficient peripheral mix
* low power modes

The most supported of the Atmel AVR MCUs are:  
* AtMega32U4
* AT90USB1286

MCU Design Goals
----------------

1. Sufficient pin count to support the keypress interrupt matrix
2. Low power and multiple power saving modes
3. Small size so as to fit on the PCB
4. Low cost

Pin Count Analysis
------------------
###Existing GH60 Analysis
This project initially aims to be compatible with the GH60 PCB form factor, supporting 60% Poker layouts.  As such, the GH60 will be examined to determine how many pins its implementation requires.

GH60 PCB revision GH60\_revC\_2016\+06\_02 was used.

Both MCU candidates offer USB, clock and reset, etc.  Therefore, only GPIO and other peripheral interfaces that appear on the MCU will be counted.

| **GH60 MCU Function** | **Pin Count** | **Comments**                                  |
| --------------------- | -------------:|:--------------------------------------------- |
| Matrix Row            |         5     |                                               |
| Matrix Col            |        14     | Pin-muxed with SPI MISO and SCK               | 
| Caps LED              |         1     | Pin-muxed with SPI MOSI                       |
| GPIO / LED            |         4     | Universal expansion connector / on-board LEDs |
|       **_TOTAL_**     |        24     |                                               |

###Proposed Design Pin Requirements

| **picoPOKER MCU Function**     | **Pin Count** | **Comments**                                    |
| ------------------------------ | -------------:|:----------------------------------------------- |
| Matrix Row                     |         5     | same as GH60                                    |
| Matrix Col                     |        14     | same as GH60                                    | 
| Matrix Interrupt               |         1     | new for picoPOKER, enables wake-on-keypress     | 
| Bluetooth Power Enable         |         1     | new for picoPOKER, BLE deep sleep load shed     | 
| Bluetooth SPI / UART           |         4     | new for picoPOKER, Adafruit BLE Friend SPI/UART |
| Bluetooth Interrupt            |         1     | new for picoPOKER, generated by BLE SPI Friend  |
| Battery Voltage Monitor ADC    |         1     | new for picoPOKER, measure battery voltage      |
| Battery Voltage Divider Enable |         1     | new for picoPOKER, ADC resistor divider enable  |
|                 **_SUBTOTAL_** |        28     |                                                 |

In order to save power, MCU will run at 3.3V.  It may not be possible to power LED properly with 3.3V.  Matrix LEDs are not a critical design element for home/office use anyway.  But for completeness, LEDs equivalent to the GH60 will be planned here.

| **LED  MCU Function** | **Pin Count** | **Comments**                                  |
| --------------------- | --- ---------:|:--------------------------------------------- |
| Caps LED              |             1 | same as GH60                                  |
| GPIO / LED            |             4 | Universal expansion connector / on-board LEDs |
|    **_SUBTOTAL_**     |             5 |                                               |


**_TOTAL REQUIRED PIN COUNT_** = 33

###Conclusion

| **Device**  | **Pin Count** | **Comments** |
|:----------- | -------------:|:------------ |
| Required    |        33     |              |
| AtMega32U4  |        26     | best case    |
| AT90USB1286 |        47     | base case    |

Therefore, AtMega32U4 does not have enough pins to service the main design functions, not even including LEDs.

AT90USB1286 has sufficient pin count, and all functions / peripherals required appear to be available.

**_WINNER_**: AT90USB1286

Power Analysis
--------------

###MCU Power Consumption Estimation

[PJRC Teensy](www.pjrc.com/teensy/index.html) has taken [power measurements](https://www.pjrc.com/teensy/low_power.html) for Teensy 2.0 (AtMega32U4) and Teensy 2.0++ (AT90USB1286).  Because those products use the same candidate MCU, those measurements are used as relevant data in leiu of the author's own ability to perform the measurements.  A relevant summary is provided below.

| **Clock** | **USB** | **Running** | **Idle** | **Sleep** | **AtMega32U4**   | **AT90USB1286** | **AtMega32U4**   | **AT90USB1286**   |
| --------- | ------- | ----------- | -------- | --------- | ----------------:| ---------------:| ----------------:| -----------------:|
|   16 MHz  |   On    |    100%     |    0%    |     0%    | (27.3)  15.7  mA | (60.2) 31.3  mA | (136.5) 51.8  mW | (301.0) 103.3  mW |
|    8 MHz  |   On    |    100%     |    0%    |     0%    | (17.9)  10.6  mA | (37.9) 19.7  mA | ( 89.5) 35.0  mW | (189.5)  65.0  mW |
|   16 MHz  |   Off   |    100%     |    0%    |     0%    | (18.9)        mA | (31.2)       mA | ( 94.5)       mW | (156.0)        mW |
|    8 MHz  |   Off   |    100%     |    0%    |     0%    | (11.0)   6.6  mA | (17.2) 9.3   mA | ( 55.0) 21.8  mW | ( 86.0)  30.7  mW |
|    8 MHz  |   Off   |     10%     |   90%    |     0%    |  (6.6)   4.0  mA | (10.7) 5.6   mA | ( 33.0) 13.2  mW | ( 53.5)  18.5  mW |
|    2 MHz  |   Off   |    100%     |    0%    |     0%    |  (4.5)   2.9  mA | (6.6)  4.0   mA | ( 22.5)  9.57 mW | ( 33.0)  13.2  mW |
|    Off    |   Off   |      0%     |    0%    |   100%    |  (0.04)  0.23 mA | (0.04) 0.23  mA | (  0.2)  0.76 mW | (  0.2)   0.76 mW |
NOTE:  Consumption when operating at 5V is shown in ().  Other is operating at 3.3V.
NOTE:  PJRC's 3.3V measurements include the ~0.2mA consumed by the 3.3V LDO powered from 5V.
NOTE:  Technically, 16MHz @ 3.3V is overclocking and may not produce reliable execution.

Assuming a **_full_** 8-hour day of office use during the work week, that would correspond to a power profile of 40 hrs/wk in a 10% interrupt mode and the remainder in sleep.  This profile would generate average power consumption profile of 0.238\*(90% Idle) + 0.762\*(100% Sleep).

| **Device**  | **Avg Instantaneous Current (90% IDLE)** | **Worst Case (Assume 100% Running)** |
| ----------  | ----------------------------------------:| ------------------------------------:|
| AtMega32U4  |                 1.127 mA                 |                             1.746 mA |
| AT90USB1286 |                 1.508 mA                 |                             2.389 mA |

####Obeservations and Conclusions
1. 10/90 @ 8MHz with USB Off is fairly representative of the intended application in daily use
2. Reducing voltage to 3.3V appreciably decreases power consumption by a factor of ~3x

**_WINNER_**: AtMega32U4

Result Summary
--------------

| **Goal**   | **Target** | **AtMega32U4** | **AT90USB1286** |
| ---------- |:----------:| -------------- | --------------- |
| Pin Count  |   \>=33    |      26        |        47       |
| Power      |  lowest    | 1.127/1.746 mA | 1.508/2.389 mA  |
| Size       |  smallest  |    smallest    |                 |
| Cost       |   least    |       ~        |        ~        |

**_OVERALL WINNER_**:  AT90USB1286 due to insufficient pin count of AtMega32U4

