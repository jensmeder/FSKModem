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

#import "JMAudioInputStream.h"

static const int EDGE_DIFF_THRESHOLD = 16384;
static const int EDGE_SLOPE_THRESHOLD = 256;
static const int EDGE_MAX_WIDTH = 8;

static const int BUFFER_BYTE_SIZE = 4096;

static const int NUMBER_OF_AUDIO_BUFFERS = 20;

typedef struct
{
	int lastFrame;
	int	lastEdgeSign;
	unsigned int lastEdgeWidth;
	int	edgeSign;
	int	edgeDiff;
	unsigned int edgeWidth;
	unsigned int plateauWidth;
}
JMAnalyzerData;

@interface JMAudioInputStream ()

@property (readonly) JMAnalyzerData* pulseData;
@property (readonly) AudioStreamBasicDescription* audioFormat;

- (void) edge: (int)height width:(unsigned)width interval:(unsigned)interval;
- (void) idle: (unsigned)samples;
- (void) reset;

@end

static int analyze( SInt16 *inputBuffer, unsigned long framesPerBuffer, JMAudioInputStream* inputStream)
{
	JMAnalyzerData *data = inputStream.pulseData;
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
				[inputStream edge:data->edgeDiff width:data->edgeWidth interval:data->plateauWidth + data->edgeWidth];
				
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
		
		int idleCheckPeriod = inputStream.audioFormat->mSampleRate / 100;
		
		if ( (idleInterval % idleCheckPeriod) == 0 )
		{
			[inputStream idle:idleInterval];
		}
	}
	
	return 0;
}


static void recordingCallback (void* inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inBuffer, const AudioTimeStamp* inStartTime, UInt32 inNumberPacketDescriptions, const AudioStreamPacketDescription *inPacketDescs)
{
	JMAudioInputStream *inputStream = (__bridge JMAudioInputStream*) inUserData;
	
	// if there is audio data, analyze it
	if (inNumberPacketDescriptions > 0)
	{
		analyze((SInt16*)inBuffer->mAudioData, inBuffer->mAudioDataByteSize / inputStream.audioFormat->mBytesPerFrame, inputStream);
	}
	
	// if not stopping, re-enqueue the buffer so that it can be filled again
	if (inputStream.running)
	{
		AudioQueueEnqueueBuffer (inAQ, inBuffer, 0, NULL);
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

-(AudioStreamBasicDescription *)audioFormat
{
	return &_audioFormat;
}

- (instancetype) initWithAudioFormat:(AudioStreamBasicDescription)format
{
	self = [super initWithAudioFormat:format];

	if (self)
	{
		_recognizers = [[NSMutableArray alloc] init];
		
		AudioQueueNewInput (&_audioFormat, recordingCallback, (__bridge void *)(self), NULL, NULL, 0, &_queueObject);
	}
	
	return self;
}

- (void) addRecognizer: (id<JMPatternRecognizer>)recognizer
{
	[_recognizers addObject:recognizer];
}

-(void)removeRecognizer:(id<JMPatternRecognizer>)recognizer
{
	[_recognizers removeObject:recognizer];
}

- (void) record
{
	[self setupRecording];
	
	[self reset];
	
	AudioQueueStart (_queueObject, NULL);
}


- (void) stop
{
	AudioQueueStop (_queueObject, TRUE);
	
	[self reset];
}


- (void) setupRecording
{
	for (int bufferIndex = 0; bufferIndex < NUMBER_OF_AUDIO_BUFFERS; ++bufferIndex)
	{
		AudioQueueBufferRef bufferRef;
		
		AudioQueueAllocateBuffer (_queueObject, BUFFER_BYTE_SIZE, &bufferRef);
		
		AudioQueueEnqueueBuffer (_queueObject, bufferRef, 0, NULL);
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
	return interval * NSEC_PER_SEC / _audioFormat.mSampleRate;
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
	AudioQueueDispose (_queueObject, TRUE);
}

@end
