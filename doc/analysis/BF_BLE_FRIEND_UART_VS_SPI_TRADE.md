Adafruit Bluefruit Friend - UART vs SPI Trade Analysis
======================================================

This is an analysis of the (potentially) blocking transfer time of a keyboard report when using either the Adafruit BLE UART Friend or the BLE SPI Friend with current tmk\_core driver.

The host driver must be able to perform the following operations:

```C
typedef struct {
    uint8_t (*keyboard_leds)(void);
    void (*send_keyboard)(report_keyboard_t *);
    void (*send_mouse)(report_mouse_t *);
    void (*send_system)(uint16_t);
    void (*send_consumer)(uint16_t);
} host_driver_t;
```

For purposes of analysis, we will assume that only one of these reports will be
sent at any given time, so only the longest transfer time for all the report
types will be used for comparison.

Keyboard Reports
----------------
The report_keyboard_t type will be compared first, as this is likely to be the
most common case.  report_keyboard_t is defined in "report.h".  We will assume
that NKRO is disabled.

```C
#define KEYBOARD_REPORT_SIZE 8
#define KEYBOARD_REPORT_KEYS 6

typedef union {
    uint8_t raw[KEYBOARD_REPORT_SIZE];
    struct {
        uint8_t mods;
        uint8_t reserved;
        uint8_t keys[KEYBOARD_REPORT_KEYS];
    };
} __attribute__ ((packed)) report_keyboard_t;
```

###BLE **_UART_** FRIEND KEYBOARD REPORT ANALYSIS
-------------------------------------------------

####Assumptions
- UART running at 9600 Baud without HW flow control
- Key presses are transferred using the `"AT+BLEKEYBOARDCODE=<mods>-00-<keys[0]>-...<keys[5]>\n"` command.  This
  command is 46 characters long.
- Driver will not wait for expected response, longest of which is `"ERROR\r\n"`, or 9 characters

####Analysis
1 byte payload = START + 8 data bits + STOP = 10 bus bits
9600 Baud = 1/9600 = 104us per bus bit

1 byte time = 10 bits/byte * 104us/bit = 1.04 ms / Byte

keyboard report time = 46 bytes (characters) * 1.04 ms / byte
                     = **47.91 ms / keyboard report**

###BLE **_SPI_** FRIEND KEYBOARD REPORT ANALYSIS
------------------------------------------------

####Assumptions
- SPI running @ 4MHz
- CS asserted 100 us before data transfer
- SDEP protocol uses 4 byte header for every packet in the message with a max payload of 16 bytes per packet.  Messages larger than 16 bytes will be broken into multiple packets.
- The CMD ID field is 0x0A00 for "AT WRAPPER" cmd
- Key presses are transerred using the `"AT+BLEKEYBOARDCODE=<mods>-00-<keys[0]>-...<keys[5]>\n"` command.  This command is 46 characters long.
- Driver will not wait for expected response, longest of which is `"ERROR\r\n"`, or 9 characters

####Analysis
4MHz SPI =  1/4MHz sec / bit = 0.25us / bit
1 byte time = 8 bits/byte * 0.25us/bit = 2 us/byte
1 message = 46 payload bytes / (16 payload bytes / packet) 
          = 2.875 packets / message (last packet has only 14 payload bytes)

1 full packet time = 20 bytes / packet * 2us / byte = 40 us
last packet time = (4 header + 14 payload bytes) * 2 us / byte = 36 us

keyboard report time =   100 us CS delay 
                       + 116 us packet time (40 + 40 + 36 us)
                       ----------
                       **216 us / keyboard report**

###KEYBOARD REPORT ANALYSIS CONCLUSION
--------------------------------------

SPI is 216us vs UART 47.91ms, or 221x faster, or O(2).  

Based on my own typing speed tests, I can type ~100 WPM with an accuracy of ~99%.  This was an avg keystroke rate of ~500 KPM, or 505 KPM / 60 sec/min = 8.42 KPS, or 118 ms / keystroke avg.  To be safe, whatever bus interface is chosen should be able to generate a new keyboard report at least 10 times per second or every 100 ms.  Also keep in mind that a keyboard report must also be sent when the key is lifted.  At this rate, some of the key lift reports will coincide with the newly pressed keys, but to be safe, assume that we will have to send keyboard reports at double the desired key press rate to account for this.  Therefore, the solution should be able to send key press reports every 50 ms.  

At first look then, UART seems completely inadquate for a blocking implementation.  If it takes ~50 ms to send the keyboard report and a new report has to be sent every 50 ms, then there is no time left over for processing of the key matrix.  However, if non-blocking interrupt driven implemenation for the UART were constructed, there might be enough time to perform the matrix processing between UART interrupts.  

Newer firmware versions for the UART allow for higher baud rates, such as 115,200.  This would increase the UART's throughput by an order of magnitude resulting in a transfer time of ~5 ms, about the key switch debounce time.  However, Adafruit doesn't seem confident in the UART performance at higher baud rates without HW flow control.  The extra effort of performing the HW flow control and that fact that the SPI is stll an order-of-magnitude faster than even this baud rate makes UART a risky choice for continually fighting timing problems at high typing speeds.

On the other hand, SPI might be higher power (due to bus frequency and pin count), but is fast enough that even a fully blocking bus transfer is adequate to virtually eliminate timing problems.

**_Recommend using SPI due to higher transfer rates and the flexibility for using as blocking._**

Due to this analysis alone, no further analysis needs to be done.
