#import "JMAudioInputStream.h"

static const int SAMPLE_RATE = 44100;
static const int NUM_CHANNELS = 1;
static const int BITS_PER_CHANNEL = 16;
static const int BYTES_PER_FRAME = NUM_CHANNELS * BITS_PER_CHANNEL / 8;

static const int EDGE_DIFF_THRESHOLD = 16384;
static const int EDGE_SLOPE_THRESHOLD = 256;
static const int EDGE_MAX_WIDTH = 8;
static const int IDLE_CHECK_PERIOD = SAMPLE_RATE / 100;

static const int MAX_BUFFER_BYTE_SIZE = 4096;

static const int NUMBER_OF_AUDIO_BUFFERS = 20;

static int analyze( SInt16 *inputBuffer, unsigned long framesPerBuffer, JMAudioInputStream* analyzer)
{
	JMAnalyzerData *data = analyzer.pulseData;
	int lastFrame = data->lastFrame;
	
	unsigned idleInterval = data->plateauWidth + data->lastEdgeWidth + data->edgeWidth;
	
	for (int i = 0; i < framesPerBuffer; i++)
	{
		int thisFrame = inputBuffer[i];
		int diff = thisFrame - lastFrame;
		
		int sign = 0;
		if (diff > EDGE_SLOPE_THRESHOLD)
		{
			// Signal is rising
			sign = 1;
		}
		else if(-diff > EDGE_SLOPE_THRESHOLD)
		{
			// Signal is falling
			sign = -1;
		}
		
		// If the signal has changed direction or the edge detector has gone on for too long,
		// then close out the current edge detection phase
		if(data->edgeSign != sign || (data->edgeSign && data->edgeWidth + 1 > EDGE_MAX_WIDTH))
		{
			if(abs(data->edgeDiff) > EDGE_DIFF_THRESHOLD && data->lastEdgeSign != data->edgeSign)
			{
				// The edge is significant
				[analyzer edge:data->edgeDiff
						 width:data->edgeWidth
					  interval:data->plateauWidth + data->edgeWidth];
				
				// Save the edge
				data->lastEdgeSign = data->edgeSign;
				data->lastEdgeWidth = data->edgeWidth;
				
				// Reset the plateau
				data->plateauWidth = 0;
				idleInterval = data->edgeWidth;
			}
			else
			{
				// The edge is rejected; add the edge data to the plateau
				data->plateauWidth += data->edgeWidth;
			}
			
			data->edgeSign = sign;
			data->edgeWidth = 0;
			data->edgeDiff = 0;
		}
		
		if(data->edgeSign)
		{
			// Sample may be part of an edge
			data->edgeWidth++;
			data->edgeDiff += diff;
		}
		else
		{
			// Sample is part of a plateau
			data->plateauWidth++;
		}
		idleInterval++;
		
		data->lastFrame = lastFrame = thisFrame;
		
		if ( (idleInterval % IDLE_CHECK_PERIOD) == 0 )
		{
			[analyzer idle:idleInterval];
		}
	}
	
	return 0;
}


static void recordingCallback (void* inUserData, AudioQueueRef inAudioQueue, AudioQueueBufferRef inBuffer, const AudioTimeStamp* inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription* inPacketDesc)
{
	JMAudioInputStream *analyzer = (__bridge JMAudioInputStream*) inUserData;
	
	// if there is audio data, analyze it
	if (inNumPackets > 0)
	{
		analyze((SInt16*)inBuffer->mAudioData, inBuffer->mAudioDataByteSize / BYTES_PER_FRAME, analyzer);
	}
	
	// if not stopping, re-enqueue the buffer so that it can be filled again
	if ([analyzer isRunning])
	{
		AudioQueueEnqueueBuffer (inAudioQueue, inBuffer, 0, NULL);
	}
}



@implementation JMAudioInputStream
{
	@private

	JMAnalyzerData _pulseData;
	NSMutableArray* _recognizers;
}

- (JMAnalyzerData*) pulseData
{
	return &_pulseData;
}

- (instancetype) initWithAudioFormat:(AudioStreamBasicDescription)format
{
	self = [super initWithAudioFormat:format];

	if (self)
	{
		_recognizers = [[NSMutableArray alloc] init];
		
		AudioQueueNewInput (&audioFormat, recordingCallback, (__bridge void *)(self), NULL, NULL, 0, &queueObject);
	}
	
	return self;
}

- (void) addRecognizer: (id<JMPatternRecognizer>)recognizer
{
	[_recognizers addObject:recognizer];
}

- (void) record
{
	[self setupRecording];
	
	[self reset];
	
	AudioQueueStart (queueObject, NULL);
}


- (void) stop
{
	AudioQueueStop (queueObject, TRUE);
	
	[self reset];
}


- (void) setupRecording
{
	for (int bufferIndex = 0; bufferIndex < NUMBER_OF_AUDIO_BUFFERS; ++bufferIndex)
	{
		AudioQueueBufferRef bufferRef;
		
		AudioQueueAllocateBuffer (queueObject, MAX_BUFFER_BYTE_SIZE, &bufferRef);
		
		AudioQueueEnqueueBuffer (queueObject, bufferRef, 0, NULL);
	}
}

- (void) idle: (unsigned)samples
{
	UInt64 nsInterval = [self convertToNanoSeconds:samples];
	for (id<JMPatternRecognizer> recognizer in _recognizers)
	{
		[recognizer idle:nsInterval];
	}
}

-(UInt64) convertToNanoSeconds:(UInt64) interval
{
	return (interval * NSEC_PER_SEC) / SAMPLE_RATE;
}

- (void) edge: (int)height width:(unsigned)width interval:(unsigned)interval
{
	UInt64 nsInterval = [self convertToNanoSeconds:interval];
	UInt64 nsWidth = [self convertToNanoSeconds:width];
	for (id<JMPatternRecognizer> recognizer in _recognizers)
	{
		[recognizer edge:height width:nsWidth interval:nsInterval];
	}
}

- (void) reset
{
	[_recognizers makeObjectsPerformSelector:@selector(reset)];
	
	memset(&_pulseData, 0, sizeof(_pulseData));
}

- (void) dealloc
{
	AudioQueueDispose (queueObject, TRUE);
}

@end
