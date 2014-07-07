FSKModem
=============

The FSKModem framework allows sending and receiving data from any iOS or OS X device via the head phone jack. It uses [frequency shift keying (FSK)](http://en.wikipedia.org/wiki/Frequency-shift_keying) to modulate a sine curve carrier signal to transmit bits. On top of that it uses a serial protocol to transmit single bytes and a simple packet protocol to cluster bytes. 

## Overview

1. [System requirements](README.md#system-requirements)
2. [Project setup](README.md#project-setup)
3. [Initial setup](README.md#initial-setup)
4. [Sending data](README.md#sending-data)
5. [Receiving data](README.md#receiving-data)
6. [Talking to Arduino](README.md#talking-to-arduino)
7. [Known Issues](README.md#known-issues)
8. [Credits / Acknowledgements](README.md#credits--acknowledgements)

## System requirements

iOS 7.0+ or Mac OS X 10.7+

## Project setup

If you want to use FSKModem you need to add the following frameworks to your _Link Binary with Library_ build phase of your project:

* AudioToolbox.framework
* AVFoundation.framework

You can either copy the source code files directly to your project or link the Static Library target (iOS) / Cocoa framework (OS X) of the FSKModem framework to your project. If you choose the Static Library approach make sure to add the following build settings to your project, otherwise you will get linker errors:

| Build Setting  | Value |
| ------------- | ------------- |
| Other Linker Flags  | `-lstdc++ -ObjC -all_load`  |
| User Header Search Paths  | `$(TARGET_BUILD_DIR)`  |

## Initial setup

```objc
JMFSKModemConfiguration* configuration = [JMModemConfiguration highSpeedConfiguration];
JMFSKModem* modem = [[JMFSKModem alloc]initWithConfiguration:configuration];

[modem connect];
```

## Sending data

```objc
NSString* textToSend = @"Hello World";
NSData* dataToSend = [textToSend dataUsingEncoding:NSASCIIStringEncoding];

[modem sendData:dataToSend];
```

##Receiving data

Register a delegate on your `JMFSKModem` instance and implement the `JMFSKModemDelegate` protocol to be notified whenever data arrives.

### Setting the delegate object

```objc
modem.delegate = myModemDelegate;
```

### Delegate implementation

```objc
-(void)modem:(JMFSKModem *)modem didReceiveData:(NSData *)data
{
	NSString* receivedText = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(@"%@", receivedText);
}
```
## Talking to Arduino

The FSKModem allows you to talk to Arduino microcontrollers by using a simple circuit. 

### Requirements

* 4-pole audio cable with 3.5mm male connectors
* Audio Jack Circuit / [Breakout](http://www.switch-science.com/catalog/600/)
* [SoftModem Arduino library](https://code.google.com/p/arms22/downloads/detail?name=SoftModem-005.zip)

_Note_: Switch Science offers a breakout board that saves you the hassle of building the circuit yourself. You can obtain one from [Tinkersoup](https://www.tinkersoup.de/a-569/).

### Sample sketch

```c++
#include <SoftModem.h>

SoftModem modem;

static const byte START_BYTE = 0xFF;
static const byte ESCAPE_BYTE = 0x33;
static const byte END_BYTE = 0x77;

static const unsigned int BAUD_RATE = 57600;

void setup()
{
  Serial.begin(BAUD_RATE);
  delay(1000);
  modem.begin();
}

void decodeByte()
{
  static boolean escaped = false;
  
  while(modem.available())
  {
    byte c = modem.read();
    
    if(escaped)
    {
      Serial.print((char)c);
      escaped = false;
      
      continue;
    }
    
    if(c == ESCAPE_BYTE)
    {
      escaped = true;
      
      continue;
    }
    
    if(c == START_BYTE)
    {
       continue;
    }
    
    if(c == END_BYTE)
    {
      Serial.print('\n');
        break;
    }
    
    Serial.print((char)c);
  }
}

void encodeByte()
{
  if(Serial.available())
  {
  modem.write(START_BYTE);
    while(Serial.available())
    {
      byte c = Serial.read();
      if(c == START_BYTE || c == END_BYTE || c == ESCAPE_BYTE)
      {
        modem.write(ESCAPE_BYTE);
      }
      modem.write(c);
    }
    modem.write(END_BYTE);
  }
}

void loop()
{
  decodeByte();
  encodeByte();
}
```
## Known Issues

iOS determines if plugged-in headphones also offer microphone capabilities. Unfortunately, iOS does not detect the Switch Science breakout board to include a microphone. If you run your app in the iOS simulator on Max OS X everything works fine as Mac OS X detects the breakout as headphones with microphone. Consequently, you can send data from your iOS devices to Arduino but not the other way around. I assume that this issue is due to a different resistance on the microphone pole of the breakout board. A custom circuit might solve this issue.

## Credits / Acknowledgements

This project uses code from arm22's [SoftModemTerminal](https://code.google.com/p/arms22/wiki/SoftModemBreakoutBoard
) application.

The guys from Perceptive Development provide a great read on their usage of [FSK in the Tin Can iOS App](http://labs.perceptdev.com/how-to-talk-to-tin-can/).
