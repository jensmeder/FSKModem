#import "JMModemConfig.h"
#import "JMFSKSerialGenerator.h"
#import "JMQueue.h"

static const float BIT_PERIOD = NSEC_PER_SEC / BAUD;

static const int SAMPLE_LIMIT_FACTOR = 100;

static const int PRE_CARRIER_BITS = BAUD / 25 + 1;
static const int POST_CARRIER_BITS = BAUD / 200 + 1;

static const int TABLE_JUMP_HIGH = FREQ_HIGH / SAMPLE_LIMIT_FACTOR;
static const int TABLE_JUMP_LOW = FREQ_LOW / SAMPLE_LIMIT_FACTOR;

static const int NUMBER_OF_DATA_BITS = 8;
static const int NUMBER_OF_START_BITS = 1;
static const int NUMBER_OF_STOP_BITS = 1;

@implementation JMFSKSerialGenerator
{
	@private

	int _sineTableLength;
	SInt16* _sineTable;
	
	float _nsBitProgress;
	unsigned _sineTableIndex;
	
	unsigned _bitCount;
	UInt16 _bits;
	
	BOOL _idle;
	BOOL _sendCarrier;

	JMQueue* _queue;
	AudioStreamBasicDescription _audioFormat;
}

- (instancetype) initWithAudioFormat:(AudioStreamBasicDescription*)audioFormat
{
	self = [super init];

	if (self)
	{
		_audioFormat = *audioFormat;
		_queue = [[JMQueue alloc]init];
		_idle = YES;
		_sineTableLength = _audioFormat.mSampleRate / SAMPLE_LIMIT_FACTOR;
		_sineTable = new SInt16[_sineTableLength];
		
		int maxValuePerChannel = (1 << (_audioFormat.mBitsPerChannel - 1)) - 1;
		
		for(int i = 0; i < _sineTableLength; i++)
		{
			// Transfer values between -1.0 and 1.0 to integer values between -sample max and sample max
		
			_sineTable[i] = (SInt16)(sin(i * 2 * M_PI / _sineTableLength) * maxValuePerChannel);
		}
	}
	
	return self;
}

-(void)dealloc
{
	delete _sineTable;
}

- (BOOL) hasNextByte
{
	// Set the output bit HIGH to indicate that there is no data transmission

	_bits = 1;

	if(_idle)
	{
		if(_queue.count > 0)
		{
			_bitCount = PRE_CARRIER_BITS;
			_sendCarrier = YES;
			_idle = NO;
			
			return YES;
		}
	}
	else
	{
		if(_queue.count > 0)
		{
			NSNumber* value = [_queue dequeueQbject];
			UInt8 byte = value.unsignedIntValue;
			_bits = byte;
			_bits <<= NUMBER_OF_START_BITS; // Set start bits to LOW
			_bits |= UINT16_MAX << (NUMBER_OF_START_BITS + NUMBER_OF_DATA_BITS); // Set stop bits to HIGH
			
			_bitCount = NUMBER_OF_DATA_BITS + NUMBER_OF_START_BITS + NUMBER_OF_STOP_BITS;
			_sendCarrier = NO;
		}
		else
		{
			_bitCount = POST_CARRIER_BITS;
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
	
		if(_nsBitProgress >= BIT_PERIOD)
		{
			if(_bitCount)
			{
				--_bitCount;
				if(!_sendCarrier)
				{
					_bits >>= 1;
				}
			}
			_nsBitProgress -= BIT_PERIOD;
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
		
	_sineTableIndex += (_bits & 1) ? TABLE_JUMP_HIGH:TABLE_JUMP_LOW;
	_sineTableIndex %= _sineTableLength;
		
	return _sineTable[_sineTableIndex];
}

- (void) writeData:(NSData *)data
{
	const char* bytes = (const char*)[data bytes];

	for (int i = 0; i < data.length; i++)
	{
		[_queue enqueueObject:[NSNumber numberWithChar:bytes[i]]];
	}
}

@end
