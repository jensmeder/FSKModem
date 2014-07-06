#import "JMModemConfig.h"
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

static const int WAVE_LENGTH_HIGH = NSEC_PER_SEC / FREQ_HIGH;
static const int WAVE_LENGTH_LOW = NSEC_PER_SEC / FREQ_LOW;
static const int HALF_WAVE_LENGTH_HIGH = WAVE_LENGTH_HIGH / 2;
static const int HALF_WAVE_LENGTH_LOW = WAVE_LENGTH_LOW / 2;

static const int SMOOTHER_COUNT = (FSK_SMOOTH * (FSK_SMOOTH + 1) / 2);

static const int DISCRIMINATOR = (SMOOTHER_COUNT * (WAVE_LENGTH_HIGH + WAVE_LENGTH_LOW) / 4);

static const int BIT_PERIOD = (NSEC_PER_SEC / BAUD);

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
}

- (instancetype) init
{
	if(self = [super init])
	{
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
	
	BOOL isHighFrequency = waveSum < DISCRIMINATOR;
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
		
		if(_recentLows + _recentHighs >= BIT_PERIOD)
		{
			// We have received the low bit that indicates the beginning of a byte
		
			[self determineStateForBit:NO];
			_recentWidth = _recentAvrWidth = 0;
			
			if(_recentLows < BIT_PERIOD)
			{
				_recentLows = 0;
			}
			else
			{
				_recentLows -= BIT_PERIOD;
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
		
		if(_recentLows + _recentHighs >= BIT_PERIOD)
		{
			BOOL isHighFrequencyRegion = _recentHighs > _recentLows;
			[self determineStateForBit:isHighFrequencyRegion];
			
			_recentWidth -= BIT_PERIOD;
			_recentAvrWidth -= BIT_PERIOD;
			
			if(_state == FSKStart)
			{
				// The byte ended, reset the accumulators
				_recentLows = _recentHighs = 0;
				return;
			}
			
			unsigned* matched = isHighFrequencyRegion?&_recentHighs:&_recentLows;
			unsigned* unmatched = isHighFrequencyRegion?&_recentLows:&_recentHighs;
			
			if(*matched < BIT_PERIOD)
			{
				*matched = 0;
			}
			else
			{
				*matched -= BIT_PERIOD;
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
	if(nsInterval <= HALF_WAVE_LENGTH_LOW + HALF_WAVE_LENGTH_HIGH)
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
		_halfWaveHistory[i] = (WAVE_LENGTH_HIGH + WAVE_LENGTH_LOW) / 4;
	}
	_recentLows = _recentHighs = 0;
}

@end
