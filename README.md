# picoPOKER - pico-power 60% Poker Keyboard

Battery-powered Bluetooth keyboard project using [pico power](http://www.atmel.com/Images/doc8349.pdf) features of AVR targetting a 60% poker form factor.

## Project Motivation

Seeking an office-oriented, mechanical keyboard platform that will fit in a variety of 60% poker cases that supports both wired USB and wireless Bluetooth battery-powered operation.

The main goals of this project are to provide the longest battery life possible without the mess of wires on a configurable platform.  As such, a custom HW platform is proposed with a purpose-built key matrix, wireless interfaces, and power controls.

Because the keyboard is intended for home/office use, backlit key LEDs are not provided so as to improve battery life.

## Supported HW platform Features

NOTE:  Some of the following features require supporting-SW to enable.

1. Targetting 60% Poker form-factor
  - Similar to GH60 key- and case-compatability
  - 5 rows X 15 columns key matrix
2. Popular Atmel AVR AT90USB1286 controller
  - Largely compatible with existing community SW
  - HW reset launches boot loader, similar to existing platforms
  - Low power external BOD reset circuit for AVR, saves BOD power when BOD fuses are disabled
    + [AVR180: External Brown-out Protection](http://www.atmel.com/Images/doc1051.pdf)
    + If BOD fuses are enabled, the internal band-gap reference will be enabled in all sleep modes and will always consume power.  This will contribute significantly to power consumption and battery life.  The BOD fuses must be disabled.  
  - powered by reulgated 3.3V or unregulated battery/VUSB, reduces power consumption
  - 8MHz clock (max for 3.3V) 
    + 16MHz @ 3.3V is technically overclocking, board can still have 16MHz crystal though
3. USB 2.0 or Bluetooth 4.0 LE for keyboard protocol connection
  - Can support simultaneous USB serial command and debug console (shares single USB connection when using USB for keyboard also)
4. Supports [Adafruit BLE UART Friend](https://www.adafruit.com/products/2479) or [Adafruit BLE SPI Friend](https://www.adafruit.com/products/2633) Bluetooth 4.0 LE Radio Modules (select one)
  - low power: [BLE Friend Current Measurements](https://learn.adafruit.com/introducing-the-adafruit-bluefruit-le-uart-friend/current-measurements)
  - add-on peripheral soldered into PWB through a header
  - Bluetooth radio can be (de)powered under SW control when not in use to save power (deep sleep or disuse)
5. Can run on battery or USB bus-power
  - Automatically selects USB bus-power when available 
6. 4.2V LiPo Battery with JST connector
  - Built-In battery charger, charges from USB bus-power
  - SW-controlled battery voltage monitor through AVR's ADC 
    + Battery monitor voltage-dividers can be disconnected by SW control to save battery power when not in use
7. Interrupt-driven matrix processing for frequent matrix power-down and fast wake to better use AVR power states
  - Power down key matrix and use AVR sleep modes when no key presses detected
  - Leave Bluetooth enabled/connected until a period of inactivity, then load shed for deep sleep
  - Use low power matrix interrupt to wake AVR when any key is pressed while in sleep mode
  - Based on [wake-up on keypress](http://www.atmel.com/Images/doc1232.pdf) 

## Intended key matrix processing model

 - continuously scan for keypresses for serveral seconds (to remain responsive) before powering-down matrix and sleeping, BLE peripherals remain active
   + if keypress interrupt detected in this state, fast wake up and process keyboard report until all keys are depressed for several seconds, then power-down matrix and go back to sleep
   + if sleeping without keypress for serveral minutes, go to a deep power-down state
 - when going to deep power down:
   + load-shed the BLE peripherals (terminate BLE connection)
   + step clock down to something slow to save power
   + wait for keypress interrupt
 - when waking from deep power down:
   + return clock step to nominal
   + power-up BLE peripheral and initialize
   + power-up matrix and scan to process keypress

## Help Wanted

1. Someone to complete a real schematic and PCB layout in KiCAD
  - As incentive, I will pay for 1 finished PCB for this person if negotiated beforehand
  - preferrably someone that has previous experience, e.g. GH60
2. Someone to support software / help develop the code base for the special features of the platform

# License

- picoPOKER - [**MIT**](LICENSE)
- All other included code retains its respective license

