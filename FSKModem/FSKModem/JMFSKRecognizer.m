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
#import "JMQueue.h"

typedef NS_ENUM(NSInteger, FSKRecState)
{
	FSKStart,
	FSKBits,
	FSKSuccess,
	FSKFail
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
	UInt8 _bits;
	FSKRecState _state;
	JMQueue* _queue;
	
	JMFSKModemConfiguration* _configuration;
}

-(instancetype)initWithConfiguration:(JMFSKModemConfiguration *)configuration
{
	self = [super init];

	if(self)
	{
		_configuration = configuration;
	
		_queue = [[JMQueue alloc]init];
		[self reset];
	}
	
	return self;
}

- (void) commitBytes
{
	while (_queue.count)
	{
		NSNumber* value = [_queue dequeueQbject];
		UInt8 input = value.unsignedIntegerValue;
		[_delegate recognizer:self didReceiveByte:input];
	}
}

- (void) dataBit:(BOOL)one
{
	if(one)
	{
		_bits |= (1 << _bitPosition);
	}
	
	_bitPosition++;
}

- (void) determineStateForBit:(BOOL)isHigh
{
	FSKRecState newState = FSKFail;
	switch (_state)
	{
		case FSKStart:
		{
			if(!isHigh) // Start Bit
			{
				newState = FSKBits;
				_bits = 0;
				_bitPosition = 0;
			}
			else
			{
				newState = FSKStart;
			}
			break;
		}
		case FSKBits:
		{
			if((_bitPosition <= 7))
			{
				newState = FSKBits;
				[self dataBit:isHigh];
			}
			else if(_bitPosition == 8)
			{
				newState = FSKStart;
				[_queue enqueueObject:[NSNumber numberWithChar:_bits]];
				[self performSelectorOnMainThread:@selector(commitBytes) withObject:nil waitUntilDone:NO];
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
	
	if (_state == FSKStart)
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
			
			if(_state == FSKStart)
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
	_state = FSKStart;
	for (int i = 0; i < FSK_SMOOTH; i++)
	{
		_halfWaveHistory[i] = (_configuration.highFrequencyWaveDuration + _configuration.lowFrequencyWaveDuration) / 4;
	}
	_recentLows = _recentHighs = 0;
}

@end
