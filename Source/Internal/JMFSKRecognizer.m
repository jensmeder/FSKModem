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

#import "JMFSKRecognizer.h"

static NSUInteger JMFSKRecognizerParityBitIndex = 8;

typedef NS_ENUM(NSInteger, JMFSKRecognizerState)
{
	JMFSKRecognizerStateStart,
	JMFSKRecognizerStateBits,
	JMFSKRecognizerStateSuccess,
	JMFSKRecognizerStateFail
} ;

static const int FSK_SMOOTH = 3;
static const int SMOOTHER_COUNT = FSK_SMOOTH * (FSK_SMOOTH + 1) / 2;

@implementation JMFSKRecognizer
{
	@private
	
	unsigned _recentLows;
	unsigned _recentHighs;
	unsigned _halfWaveHistory[FSK_SMOOTH];
	unsigned _bitPosition;
	unsigned _recentWidth;
	unsigned _recentAvrWidth;
	UInt16 _bits;
	JMFSKRecognizerState _state;
	
	JMFSKModemConfiguration* _configuration;
}

-(instancetype)initWithConfiguration:(JMFSKModemConfiguration *)configuration
{
	self = [super init];

	if(self)
	{
		_configuration = configuration;

		[self reset];
	}
	
	return self;
}

- (void) dataBit:(BOOL)one
{
	if(one)
	{
		_bits |= (1 << _bitPosition);
	}
	
	_bitPosition++;
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

- (void) determineStateForBit:(BOOL)isHigh
{
	JMFSKRecognizerState newState = JMFSKRecognizerStateFail;
	switch (_state)
	{
		case JMFSKRecognizerStateStart:
		{
			if(!isHigh) // Start Bit
			{
				newState = JMFSKRecognizerStateBits;
				_bits = 0;
				_bitPosition = 0;
			}
			else
			{
				newState = JMFSKRecognizerStateStart;
			}
			break;
		}
		case JMFSKRecognizerStateBits:
		{
			if((_bitPosition <= JMFSKRecognizerParityBitIndex))
			{
				newState = JMFSKRecognizerStateBits;
				[self dataBit:isHigh];
			}
			else
			{
				UInt8 byte = _bits;

				BOOL parityBit = (_bits >> 8) & 1;
				
				if ([self evenParity:byte] == parityBit)
				{
					dispatch_async(dispatch_get_main_queue(),
					^{
						[_delegate recognizer:self didReceiveByte:byte];
					});
				}
				
				newState = JMFSKRecognizerStateStart;
				
				_bits = 0;
				_bitPosition = 0;
			}
			break;
		}
		default:
		{
		}
	}
	_state = newState;
}

- (void) processHalfWave:(unsigned)width
{
	// Calculate necessary values
	
	int discriminator = SMOOTHER_COUNT * (_configuration.highFrequencyWaveDuration + _configuration.lowFrequencyWaveDuration) / 4;

	// Shift historic values to the next index
	
	for (int i = FSK_SMOOTH - 2; i >= 0; i--)
	{
		_halfWaveHistory[i+1] = _halfWaveHistory[i];
	}
	_halfWaveHistory[0] = width;
	
	// Smooth input
	
	unsigned waveSum = 0;
	for(int i = 0; i < FSK_SMOOTH; ++i)
	{
		waveSum += _halfWaveHistory[i] * (FSK_SMOOTH - i);
	}
	
	// Determine frequency
	
	BOOL isHighFrequency = waveSum < discriminator;
	unsigned avgWidth = waveSum / SMOOTHER_COUNT;
	
	_recentWidth += width;
	_recentAvrWidth += avgWidth;
	
	if (_state == JMFSKRecognizerStateStart)
	{
		if(!isHighFrequency)
		{
			_recentLows += avgWidth;
		}
		else if(_recentLows)
		{
			_recentHighs += avgWidth;
			
			// High bit -> error -> reset
			
			if(_recentHighs > _recentLows)
			{
				_recentLows = _recentHighs = 0;
			}
		}
		
		if(_recentLows + _recentHighs >= _configuration.bitDuration)
		{
			// We have received the low bit that indicates the beginning of a byte
		
			[self determineStateForBit:NO];
			_recentWidth = _recentAvrWidth = 0;
			
			if(_recentLows < _configuration.bitDuration)
			{
				_recentLows = 0;
			}
			else
			{
				_recentLows -= _configuration.bitDuration;
			}
			
			if(!isHighFrequency)
			{
				_recentHighs = 0;
			}
		}
	}
	else
	{
		if(isHighFrequency)
		{
			_recentHighs += avgWidth;
		}
		else
		{
			_recentLows += avgWidth;
		}
		
		if(_recentLows + _recentHighs >= _configuration.bitDuration)
		{
			BOOL isHighFrequencyRegion = _recentHighs > _recentLows;
			[self determineStateForBit:isHighFrequencyRegion];
			
			_recentWidth -= _configuration.bitDuration;
			_recentAvrWidth -= _configuration.bitDuration;
			
			if(_state == JMFSKRecognizerStateStart)
			{
				// The byte ended, reset the accumulators
				_recentLows = _recentHighs = 0;
				return;
			}
			
			unsigned* matched = isHighFrequencyRegion?&_recentHighs:&_recentLows;
			unsigned* unmatched = isHighFrequencyRegion?&_recentLows:&_recentHighs;
			
			if(*matched < _configuration.bitDuration)
			{
				*matched = 0;
			}
			else
			{
				*matched -= _configuration.bitDuration;
			}
			
			if(isHighFrequency == isHighFrequencyRegion)
			{
				*unmatched = 0;
			}
		}		
	}	
}

- (void) edge:(int)height width:(UInt64)nsWidth interval:(UInt64)nsInterval
{
	if(nsInterval <= _configuration.lowFrequencyWaveDuration / 2 + _configuration.highFrequencyWaveDuration / 2)
	{
		[self processHalfWave:(unsigned)nsInterval];
	}
}

- (void) idle: (UInt64)nsInterval
{
	[self reset];
}

- (void) reset
{
	_bits = 0;
	_bitPosition = 0;
	_state = JMFSKRecognizerStateStart;
	for (int i = 0; i < FSK_SMOOTH; i++)
	{
		_halfWaveHistory[i] = (_configuration.highFrequencyWaveDuration + _configuration.lowFrequencyWaveDuration) / 4;
	}
	_recentLows = _recentHighs = 0;
}

@end
