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

#import "JMFSKSerialGenerator.h"
#import "JMFSKModemConfiguration.h"

static const int SAMPLE_LIMIT_FACTOR = 100;

static const int NUMBER_OF_DATA_BITS = 9;
static const int NUMBER_OF_START_BITS = 1;
static const int NUMBER_OF_STOP_BITS = 2;

@implementation JMFSKSerialGenerator
{
	@private
	
	float _nsBitProgress;
	unsigned _sineTableIndex;
	
	unsigned _bitCount;
	UInt16 _bits;
	
	BOOL _idle;
	BOOL _sendCarrier;

	NSMutableData* _buffer;
	AudioStreamBasicDescription _audioFormat;
	JMFSKModemConfiguration* _configuration;
	
	NSMutableData* _sineTableData;
}

- (instancetype) initWithAudioFormat:(AudioStreamBasicDescription*)audioFormat configuration:(JMFSKModemConfiguration*)configuration
{
	self = [super init];

	if (self)
	{
		_buffer = [NSMutableData data];
		_configuration = configuration;
		_audioFormat = *audioFormat;

		_idle = YES;
		NSUInteger sineTableLength = _audioFormat.mSampleRate / SAMPLE_LIMIT_FACTOR;
		
		_sineTableData = [NSMutableData dataWithCapacity:sineTableLength * sizeof(SInt16)];
		
		int maxValuePerChannel = (1 << (_audioFormat.mBitsPerChannel - 1)) - 1;
		
		for(int i = 0; i < sineTableLength; i++)
		{
			// Transfer values between -1.0 and 1.0 to integer values between -sample max and sample max
		
			SInt16 value = (SInt16)(sin(i * 2 * M_PI / sineTableLength) * maxValuePerChannel);
			[_sineTableData appendBytes:&value length:sizeof(SInt16)];
		}
	}
	
	return self;
}

-(BOOL) evenParity:(UInt8)byte
{
	NSUInteger numberOfOnes = 0;
	
	for(int i = 0; i < 8; i++)
	{
		numberOfOnes += byte & (1 << i) ? 1:0;
	}
	
	return numberOfOnes % 2 != 0;
}

- (BOOL) hasNextByte
{
	// Set the output bit HIGH to indicate that there is no data transmission

	_bits = 1;

	if(_idle)
	{
		if(_buffer.length)
		{
			int preCarrierBitsCount = _configuration.baudRate / 25 + 1;

			_bitCount = preCarrierBitsCount;
			_sendCarrier = YES;
			_idle = NO;
			
			return YES;
		}
	}
	else
	{
		if(_buffer.length)
		{
			UInt8 byte = 0;
			[_buffer getBytes:&byte length:sizeof(byte)];
			[_buffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
			
			_bits = byte;
			
			// Calculate even parity
			
			if ([self evenParity:byte])
			{
				_bits |= 1 << 8;
			}
			
			_bits <<= NUMBER_OF_START_BITS; // Set start bits to LOW
			_bits |= UINT16_MAX << (NUMBER_OF_START_BITS + NUMBER_OF_DATA_BITS); // Set stop bits to HIGH
			
			_bitCount = NUMBER_OF_DATA_BITS + NUMBER_OF_START_BITS + NUMBER_OF_STOP_BITS;
			_sendCarrier = NO;
		}
		else
		{
			int postCarrierBitsCount = _configuration.baudRate / 200 + 1;
		
			_bitCount = postCarrierBitsCount;
			_sendCarrier = YES;
			_idle = YES;
		}
		
		return YES;
	}
	
	return NO;
}

- (void) outputStream:(JMAudioOutputStream *)stream fillBuffer:(void *)buffer bufferSize:(NSUInteger)bufferSize
{
	SInt16* sample = (SInt16*)buffer;
	BOOL underflow = NO;

	if(!_bitCount)
	{
		underflow = ![self hasNextByte];
	}
	
	for(int i = 0; i < bufferSize; i += _audioFormat.mBytesPerFrame, sample++)
	{
		// Send next bit
	
		if(_nsBitProgress >= _configuration.bitDuration)
		{
			if(_bitCount)
			{
				--_bitCount;
				if(!_sendCarrier)
				{
					_bits >>= 1;
				}
			}
			_nsBitProgress -= _configuration.bitDuration;
			if(!_bitCount)
			{
				underflow = ![self hasNextByte];
			}
		}
		
		*sample = [self modulate:underflow];

		if(_bitCount)
		{
			float sampleDuration = NSEC_PER_SEC / _audioFormat.mSampleRate;
			_nsBitProgress += sampleDuration;
		}
	}
}

-(SInt16) modulate:(BOOL)underflow
{
	if(underflow)
	{
		// No more bits to send
	
		return 0;
	}

	// Modulate bits to high and low frequencies
	
	int highFrequencyThreshold = _configuration.highFrequency / SAMPLE_LIMIT_FACTOR;
	int lowFrequencyThreshold = _configuration.lowFrequency / SAMPLE_LIMIT_FACTOR;
		
	_sineTableIndex += (_bits & 1) ? highFrequencyThreshold:lowFrequencyThreshold;
	_sineTableIndex %= _sineTableData.length / sizeof(SInt16);
	
	SInt16 value = 0;
	[_sineTableData getBytes:&value range:NSMakeRange(sizeof(SInt16) * _sineTableIndex, sizeof(SInt16))];
	
	return value;
}

- (void) writeData:(NSData *)data
{
	[_buffer appendData:data];
}

@end
