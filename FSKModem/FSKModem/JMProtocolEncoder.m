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

#import "JMProtocolEncoder.h"

static const UInt8 START_BYTE = 0xFF;
static const UInt8 ESCAPE_BYTE = 0x33;
static const UInt8 END_BYTE = 0x77;

@implementation JMProtocolEncoder

-(NSData *)encodeData:(NSData *)data
{
	NSMutableData* encodedData = [NSMutableData dataWithCapacity:data.length];
	
	// Append start byte
	
	[encodedData appendBytes:&START_BYTE length:1];
	
	// Escape bytes
	
	const UInt8* dataBytes = data.bytes;
	
	for (int i = 0; i < data.length; i++)
	{
		UInt8 dataByte = dataBytes[i];
	
		if (dataByte == START_BYTE || dataByte == END_BYTE || dataByte == ESCAPE_BYTE)
		{
			[encodedData appendBytes:&ESCAPE_BYTE length:1];
		}
		
		[encodedData appendBytes:&dataByte length:1];
	}
	
	// Append end byte
	
	[encodedData appendBytes:&END_BYTE length:1];
	
	return encodedData;
}

@end
