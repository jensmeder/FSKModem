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
