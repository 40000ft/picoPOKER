Estimated Battery Life
======================

This analysis is not intended to be comprehensive or provide an exact calculation for the expected battery life.  Assumptions about power consumptions, user behavior, and the platform hardware are liberally applied.  This analysis is only intended to give a reasonable flavor of what kind of battery life can be expected, make sure reasonable HW design decisions are made, and to try to uncover where power consumptions may be too high.

Ideally, picoPOKER is targeting a minumum of 3-6 months of daily office use operating from a 500 mAh or 1200 mAh Lithium-Polymer or Lithium-Ion flat battery (so it will fit inside the keyboard case).  LiPo batteries with capacities as large as 2500 mAh are readily available to hobbyists through sites like [Adafruit](http://www.adafruit.com), but adequate runtime with the smallest battery possible is desirable for cost, size and weight reasons.  Obviously adding more battery capacity for increased life is possible, but at some point the capacity is adequate.  

Estimated Component Consumption
-------------------------------

###AT90USB1286

[PJRC has already taken power measurements for Teensy 2.0++ (AT90USB1286).](https://www.pjrc.com/teensy/low_power.html)  Because Teensy 2.0++ uses the same MCU and has little else consuming power on the board, those measurements are useful as relevant data in leiu of the author's own ability to perform the measurements.  A relevant summary is provided below.

| **Clock** | **USB** | **Running** | **Idle** | **Sleep** | **AT90USB1286 @ 3.3V** |
| --------- | ------- | ----------- | -------- | --------- | ----------------------:|
|   16 MHz  |   On    |    100%     |    0%    |     0%    |               31.1  mA |
|    8 MHz  |   On    |    100%     |    0%    |     0%    |               19.5  mA |
|    8 MHz  |   Off   |    100%     |    0%    |     0%    |                9.1  mA |
|    8 MHz  |   Off   |     10%     |   90%    |     0%    |                5.3  mA |
|    2 MHz  |   Off   |    100%     |    0%    |     0%    |                3.8  mA |
|    Off    |   Off   |      0%     |    0%    |   100%    |                0.03 mA |
NOTE:  PJRC's 3.3V measurements include an additional ~0.2mA consumed by the 3.3V LDO powered from 5V.  This has already been removed from the table.
NOTE:  Based on the difference between PJRC measured values and the datasheet for sleep modes, as well as the author's knowledge of how his own teensy++ fuse settings were received, it is believed that the teensy++ measured values for sleep modes likely have the BOD and watchdog enabled.
NOTE:  Technically, 16MHz @ 3.3V is overclocking and may not produce reliable execution.

The AT90USB1286 datasheet also lists the following:

| **Clock** | **VCC** | **Mode**   | **USB** | **WDT** | **BOD** | **ICC (typ)** | **ICC (max)** |
| --------- | ------- | --------   | ------- | ------- | ------- | -------------:| -------------:|
|    16 MHz |   5.0 V | Running    |     OFF |         |         |       19.0 mA |       30.0 mA |
|     8 MHz |   5.0 V | Running    |     OFF |         |         |       10.0 mA |       18.0 mA |
|     8 MHz |   3.0 V | Running    |     OFF |         |         |        5.0 mA |       10.0 mA |
|     4 MHz |   3.0 V | Running    |     OFF |         |         |        2.5 mA |        5.0 mA |
|     OFF   |   3.0 V | Power-Down |     OFF |    ON   |   ON    |         30 uA |               |
|     OFF   |   3.0 V | Power-Down |     OFF |    ON   |  OFF    |         10 uA |               |
|     OFF   |   3.0 V | Power-Down |     OFF |   OFF   |  OFF    |          2 uA |               |

Based on these numbers, a good estimate for the usage model in mind is:
**Running**: PJRC's 10/90% of 5.3 mA
**Sleep**: Datasheet's 2 uA

####BOD Circuit

The AT90USB1286 has an internal bandgap voltage reference used for:  
- Brown-Out Detection (BoD) (set by fuses)
- whenever the ADC is enabled
- As a source to the Analog Comparator
The internal bandgap reference consumes ~10uA when any of these functions are  enabled (datasheet table 9-4).

If the Brown-out Detector (BOD) is enabled by the BODLEVEL Fuses, it will be enabled in all sleep modes, and hence, always consume power. In the deeper sleep modes, this will contribute significantly to the total current consumption.  The BOD circuit  consumes ~25uA (datasheet table 9-3) when enabled.

The 4.2V LiPo battery technology targeted for this design is essentially dead when it reaches a voltage of 3.4V, and the battery protection circuits will cut-off at 3.0V.  Therefore, a BOD circuit may not be strictly necessary.  However, the power consumption of the BOD ciruit can be siginficantly reduced by disabling it in the fuses and instantiating a low-power external BOD circuit as guaranteed protection from brown-out.  Note that the AT90USB1286 has an independent power-on reset circuit.

[Atmel App Note "AVR180: External Brown-Out Protection"](http://www.atmel.com/Images/doc1051.pdf) suggests a low-power external BOD circuit suitable for battery-powered applications.  This circuit has a threshold of 3.0 +/- 0.3V and consumes ~0.5uA @ 3.0V.  picoPOKER intends to use this circuit.

###Adafruit Bluefruit SPI/UART Friend Power Usage

First of all, why not use the [Adafruit Bluefruit EZ-key](https://www.adafruit.com/products/1535) which already has driver support in projects like tmk\_core and qmk\_firmware, and has a generally more usable serial interface?  [Current measurements](https://learn.adafruit.com/introducing-bluefruit-ez-key-diy-bluetooth-hid-keyboard/faqz) for the EZ-key indicate a static 25 mA current draw at all times while paired, and an extra 2 mA while transmitting for a total of 27 mA. That would make this most power-hungry component of the design by a wide margin and will kill battery life.  This module is not likley to be Bluetooth Low Energy, which consumes considerably less power.   So, this is not a tenable choice.  On the other hand, the Bluefruit LE Friend modules are low-energy, easily obtained, have support for keyboard, HID and battery services, and are small.

Adafruit has [published current measurements](https://learn.adafruit.com/introducing-the-adafruit-bluefruit-le-uart-friend/current-measurements) for the Bluefruit LE UART Friend module.  Power consumption for the SPI module is assumed to be similar.  Results are summarized below.

| **Mode**              | **Avg Current** | **Peak Current** | **Expected Battery Life (1200 mAh)** |
| --------------------- | ---------------:| ----------------:|:------------------------------------ |
| Fast Advertising Mode | 1.44 mA         | 13.4 mA          | 832 Hours (~34.6 days)               |
| Slow Advertising Mode | 1.25 mA         | 13.5 mA          | 956 Hours (~40 days)                 |
| Connected Mode        | 1.86 mA         | 15.2 mA          | 645 Hours (~26.8 days)               |

This module has its own 3.3V LDO and can be used with a wide input voltage.  

####Load Shed Circuit (MIC9406x)

During long deep sleep periods, there is no reason to maintain a wireless connection to the host.  In order to allow the posssibility to load-shed the bluetooth module, a high-side power switch, Micrel MIC9406x, is provided to cut power to this module when desired.  This IC is selected, rather than a home-brew high-side P-Channel FET circuit (with biasing), in order to minimize power-losses while active.  picoPOKER is really trying to get an ideal switch here.

MIC9406x has an integral pull-down resistor on the enable input to ensure power is not connected until commanded, but appears to have a low power draw when driven.

It is not clear to the author what the power consumption for this device will be based on the datasheet for the desired mode of operation.  However, the following assumtpions will be made:

| **Characteristic**     | **Value** | **picoPOKER Mode** | **Comments**
| ---------------------- | ---------:| ------------------ | ---
| Quiescent Current Draw |      2 uA | Running            | Assumed power to run the charge pump
| Ron (typical)          |   77 mOhm | Running            | Small enough that we assume the voltage drop has a neglible effect on the BLE power draw
| Micropower Shutdown    |    < 1 uA | Deep Sleep         | Assumed static power draw

###3.3V LDO (MIC5225)

####3.3V LDO vs running direct from battery

Some thought has gone into whether it would be best to run directly from the battery, or to use a 3.3V regulator for lowest power.  The trade off seems to be the difference between:
* power consumed by the LDO during sleep times vs power consumed by the MCU at higher voltage during run times  
* complications around meeting the USB spec for powering the MCU's USB circuits
* providing known stable voltages in the system for use with battery monitoring ADC inputs (internal bandgap reference has a wide error %, would be nice to use VCC if it were stable)

The power consumption difference when operating the MCU at higher voltages is appreciable, almost 1/2 the current draw at 3.3V compared to 5V for most of the profiles measured by PJRC, on the order of mA.  However, this will only come into play during run times.  During sleep, the current draw is similar between VCC voltages.  On the other hand, the LDO will add ony uA (or less) of additional current draw during run times, but will add a low-grade static current draw during sleep on the order of uAs.  The answer to how best to provide the lowest power consumption then seems to depend on the use model of how much time picoPOKER is spending in runtime vs sleep.  If the majority of time is spent in sleep, higher current draw momentarily during runtime may be an acceptable trade off for the reduced current draw during the majority time sleeping, so long as the higher current draw isn't outrageously high.  However, the low-grade static current draw of the LDO during sleep times could be low enough to be unappreciable in the end.

|                               | **Battery Direct**                  | **LDO**    |
| ----------------------------- | ----------------------------------- | ---------- |
| **VCC**                       | Unregulated LiPo battery (4.2-3.4V) | LDO (3.3V) |
| **UVCC**                      |                      VCC (4.2-3.4V) |     (open) |
| **UCAP**                      |                         (capacitor) | VCC (3.3V) |
| **Pad Regulator**             |                                 ON  |       OFF  |
| **UVCC/UCAP Compliant Range** |                           5.5-3.4V  |  3.6-3.0V  |
| **NOTES**                     |                              2,3,4  |     5,6,7  |

1. All the other topologies that were explored were either variations of these that were too similar to matter, presented complications, didn't meet specs, or were just plain silly for other reasons.
2. Recommended by datasheet Figure 22-5 for self-powered applications with 3.4-5.5V IO (unregulated battery).
3. Potential dynamic power increase from running at higher VCC with a fully charged battery.
4. Internal bandgap is the only stable reference in the system for ADC.  Internal bandgap introduces a 7% error.
5. Recommended by datasheet Figure 22-6 for self-powered applications with 3.0-3.6V IO (regulated power).
6. Potential static power increase from LDO during sleep.  LDO still regulates to 3.3V even when little current is being pulled.
7. LDO provides a stable reference voltage for the ADC, with a tighter tolerance.

Running with the LDO is the initial preference due to providing a stable ADC reference with a tighter tolernace.  If the LDO current draw during sleep is tolerable for the expected battery life, then this seems like the better approach.  However, in order to provide flexability, picoPOKER will provide solder jumpers and/or "no stuff" options for both modes in-case the project default turns out to be wrong based on estimates.  

Without an "off" switch on the keyboard, it is expected that picoPOKER will spend more time in sleep than run modes.

####LDO Analysis
The 3.3V LDO will only be used to power the MCU and its circuits.

For purpsoes of analysis, an "operational" current draw and a "sleeping" current draw will be calculated.

Since we are now attempting to calculate the operational current draw as part of this analysis, an assumed value of 10 mA max will be used to determine current draw for the regulator, based on the datasheet listing this Iout value specifically and the max AT90USB1286 current draw numbers for 3.3V @ 8MHz without USB.  Since LDOs are less efficient the higher the input voltage compared to the regulated output voltage, this analysis will assume the input voltage is 3.7V, which is the average voltage of a LiPo battery. 

| **Matrix Mode** | **Estimated MIC5225 Current** |
| --------------- |------------------------------:|
| Running         |     (Ignd @ 10 mA Iout) 60 uA |
| Sleep           |     (Ignd @ 10 uA Iout) 20 uA |

###A Note on the Battery Charger (MIC73831-2ACI/OT)

The battery charger IC is only engergized by the USB 5V.  Until such time as the USB charger is connected, the battery charger IC has no drain on the battery (except for maybe a slight leak).  When 5V is connected, it becomes the main power source and the battery is no longer being used and instead is charged.  Since we are no longer running on battery during that time, its power draw is not a concern for battery life.

###Key Matrix

The key matrix will certainly draw power whenever those circuits are energized as well.  However it is difficult to say how much power it will take and is quite difficult to estimate because it depends on how much the user is typing.  The MCU's integral pull-ups have a value of (20-50 kOhms).  Assuming a 0.3V drop over the diodes and worst case pull-up values, each key press will consume 150 uA instantaneous current.  In order to make a simple calcuation, we will assume that at least one matrix key is pressed for as long as the MCU is not idle or sleeping.  Since we're probably using the 10% active / 90% idle consumption numbers for the MCU, we'll assume that a key is being pressed 10% of the MCU's non-sleep time.  This would be a 15 uA contribution from the matrix.

###LEDs

LEDs are a user preference.  Obviously power consumption from LEDs will be appreciable, but again, difficult to know how many are installed and when they are acivated, etc.  LEDs are personal preference and are left to the user to include or not.  It is advisable to have a minimal set of LEDs to maximize battery life.  It may not even be possible to get bright LEDs with a 3.3V source, or maybe they will have to operate directly from the unregulated battery voltage which probably isn't that much better.

###Battery Voltage Monitor

A rudimentary voltage monitor is planned for crudely reporting the remaining battery life through the MCU's ADC.    The max voltage on an ADC pin must be less than the reference voltage.  In this case, the reference is planned to be VCC.  Since the max battery voltage of 4.2V exceeds the VCC voltage of 3.3V, the battery voltage to the ADC must be scaled with a resistor divider.   However, this resistor divider will continually consume power.  But the battery voltage doesn't change that quickly and so doesn't need to be measured often, or at all when asleep, and so the power consumption is mostly a waste if left energized all the time.

Options:
1. Don't have an ADC input for the battery voltage
2. Make the divider sufficiently high R that the impact is tolerable for most users without any additional care
3. Proivde a disconnect mechanism to load shed when not in use

_Option 1_:  This does rather defeat the point.  We would like to be able to measure the battery voltage and alert the user through the bluetooth battery service when they need to recharge.  Admitedly, voltage is not a reliable indicator of battery life for LiPo batteries, but it is better than having nothing.  A crude guess at the remaining life can be made from the known discharge curves.  The battery life  doesn't have to be precise.  It is only intended to give the user a rough estimate.

_Option 2_:  The Analog Input Resistance (Rain) on an ADC input is 100 MOhm and is optimized for analog signals with an output impedance of 10 kOhm or less.  A resistor divider with a large R value would consume less power (or a tolerable amount), and so higher is preferrable.  

Some examples of current draw, assuming a 3.7V battery, just to get a flavor.
| **Total R value** | **Static current draw** |
| -----------------:| -----------------------:|
|               1 M |                 3.7  uA |
|             100 K |                37.0  uA |
|              10 K |               370.0  uA |

1M resistors produce a low current draw, but even uA's may have an appreciable effect.  But 1M is outside of the range suggested by the vendor for optimal performance.  Even 100k is getting closer, but 10's of uA staticially consuming power is too much.  It seems a static divider is a poor choice. 

_Option 3_:  A high-side switch to the divider that is controlled by the MCU can be used to only energize the divider when a measurement needs to be taken.  The switch can be a P-Channel FET circuit or even just another MIC9406x used to loadshed the BLE module.  In this case, the divider only consumes power while a measurement is being taken. 

**Winner:**  Option 3.  Allows to still take a measurement while reducing battery life impact.

The first matter, then, is what value the divider should be.  The scaling should be designed to give maximum range on the ADC input so as to have the most accuracy.  The max battery voltage of 4.2 should correspond to an ADC input of 3.3V, which will read as max ADC value.  This corresponds to a scaling of 0.7857 of the battery voltage.  

Resistors in the megaOhm range provide the lowest current, but are probably to large to get a good reading from.  So, 100's of kOhms is likely to proidve a little bit better reading, but is still outside of the recommendation.  In order to get around that, a 0.1uF (100nF) capacitor will be placed on the divider to provision a little extra low-resistance current source for the measurment.  This structure will only have to charge a 14nF capacitor in the S/H circuit.  The resistors should be 1% resistors for accuracy.  Resistor values of 365K (gnd side) and 100K (battery side) meet the criteria and provide a current draw of 8 uA when energized.

Of course, the control circuit will consume some power as well.  As an estimate, the MIC9406x numbers will be used.  2 uA while energized, < 1 uA while disabled.

| **State** | **Current** |
| --------- | ----------- |
| Energized |       10 uA | 
| Disabled  |     <  1 uA |

Allowing for a conversion time of 1ms, and supposing that a measuremnt is only taken once every minute, a duty cycle factor of 0.001/60 = 16.667E-6 is applied to the energized number to get an estimated average.

| **Matrix Mode** | **Current** |
| --------------- | ----------- |
| Running         |      < 1 uA |
| Sleep           |      < 1 uA |

Essentially, the impact of this circuit can be disregarded due to the load-shed control and the exepected duty cycle, even with resistor values in the 10K range.  

###Component Estimate Summary

| **Component**    | **Running** | **Sleeping** | **10/90** |
| ---------------- | -----------:| ------------:| ---------:|
| AT90USB1286      |     5.3  mA |         2 uA |    532 uA |  
| BOD              |     0.5  uA |       0.5 uA |    0.5 uA | 
| BLE              |     1.86 mA |         0 uA |    186 uA | 
| BLE MIC9406x     |     2    uA |       < 1 uA |    1.1 uA | 
| LDO              |    60    uA |        20 uA |     24 uA | 
| Matrix           |    15    uA |         0 uA |    1.5 uA | 
| LEDs             |     N/A     |      N/A     |    N/A    |
| Battery Monitor  |  <  1    uA |       < 1 uA |    < 1 uA | 
| **TOTAL**        |     7.24 mA |     24.5  uA |    745 uA | 
| **500 mAh**      |   2.87 Days |   2.33 Years |   28 Days |  
| **1200 mAh**     |   6.9  Days |   5.59 Years | 2.2 Months|
| **2500 mAh**     |  14.38 Days |  11.64 Years | 4.6 Months|

Usage Model (Run/Sleep Duty Cycle)
----------------------------------

The expected power states of the platform can be broken down as follows:

1. **_Run_**  
  The platform is actively processing key presses and transmitting BLE.  The highest power state.  Transitions to Idle when there are no keys being pressed.
2. **_Idle_**  
  The BLE module is still powered and connected to the host, but the matrix is powered down and the MCU is sleeping or idling, waiting for a key press or timer interrupt.  This state is entered when there are no active keys being pressed for serveral scans of the matrix.  After a sufficient period of time in this state without a key press (several minutes?), picoPOKER will transition to deep sleep.
3. **_Deep Sleep_**  
  The platform is in its lowest power state.  The BLE module is load shed and disconnected from the host.  The MCU is in its deepest sleep waiting for a key press interrupt to wake it up.  This state is entered when no key activity has been detected for a sufficient time.  When a key press interrupt is recieved, the MCU will reinitialize the BLE module and return to the run state to scan the matrix.  The first key press probably won't get processed because the platform state can't be restored fast enough to scan the matrix before the key is released.  It will just wake up the keyboard.

The previous section attempted to come up with some estimated values for  current consumption when the platform is in a deep sleep, and when running.  The "running" numbers from the previous section already include power states 1 & 2 together and account for a guess at the duty cycle between idling (10%) and processing (90%).  What remains is to determine a duty cycle for sleeping vs. not sleeping.

As a rough estimate, suppose that a worker uses the computer for an 8-hour work day, 5 days per week, for a total of 40 out of 168 possible hours per week.  Since work weeks repeat this way, it will work as a 1st framework guess at an average.  That immediately provides a duty cycle of ~40/168 = 23.8% running to 76.2% sleeping.  Since the battery life is completely dominated by the "running" power, this scaling only results an estimate of 4x better battery life from the raw "running" estimates.  Even with 2500 mAh battery, this only results in ~60 days or ~2 months of operation, which doesn't meet the target of 3-6 months on a 500 or 1200 mAh battery.  

But of course the keyboard isn't actually processing the matrix for the entire 8 hour work day.  Workers often leave their desk for meetings and appointments, or maybe there are extended periods where certain tasks on the computer, such as browsing and reading, which don't require the keyboard, are being performed.  And so there will be periods of sleep within the 8 hour work day too, and probably more IDLE time between key presses than our 10/90% MCU model suggests.  Being that there's enough slop in this model already, suppose that the keyboard is only really "active" or being used 1/2 of the work day, or 4 hours per day, 5 days per week.  This is a duty cycle of (4\*5)/168 = 11.9% running, 88.1% sleeping.  This results in the following estimated battery life:

| **Battery Capacity** | **Estimated picoPOKER battery life** |
| --------------------:| ------------------------------------:|
|              500 mAh |           23 Days
|             1200 mAh |         56 Days / ~2 Months
|             2500 mAh |        118 Days / ~4 Months




