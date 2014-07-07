//	The MIT License (MIT)
//
//	Copyright (c) 2014 Jens Meder
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

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
		byte data = modem.read();
    
		if(escaped)
		{
			Serial.print((char)data);
			escaped = false;
      
			continue;
		}
    
		if(data == ESCAPE_BYTE)
		{
			escaped = true;
      
			continue;
		}
    
		if(data == START_BYTE)
		{
			continue;
		}
    
		if(data == END_BYTE)
		{
			Serial.print('\n');
			break;
		}
    
		Serial.print((char)data);
	}
}

void encodeByte()
{
	if(Serial.available())
	{
		modem.write(START_BYTE);
		while(Serial.available())
		{
			byte data = Serial.read();
			if(data == START_BYTE || data == END_BYTE || data == ESCAPE_BYTE)
			{
				modem.write(ESCAPE_BYTE);
			}
			modem.write(data);
		}
		modem.write(END_BYTE);
	}
}

void loop()
{
	decodeByte();
	encodeByte();
}
