#import <AudioToolbox/AudioToolbox.h>
#import "JMAudioOutputStream.h"

static const int NUMBER_AUDIO_DATA_BUFFERS = 3;
static const int BUFFER_BYTE_SIZE = 0x400;


static void playbackCallback (void* inUserData, AudioQueueRef inAudioQueue, AudioQueueBufferRef	bufferReference)
{
	JMAudioOutputStream *player = (__bridge JMAudioOutputStream*) inUserData;
	if (player.stopped)
	{
		return;
	}
	[player.audioSource outputStream:player fillBuffer:bufferReference->mAudioData bufferSize:player.bufferByteSize];

	bufferReference->mAudioDataByteSize = player.bufferByteSize;

	AudioQueueEnqueueBuffer (inAudioQueue, bufferReference, player.bufferPacketCount, player.packetDescriptions);
}

@implementation JMAudioOutputStream
{
	@private

	AudioQueueBufferRef	buffers[NUMBER_AUDIO_DATA_BUFFERS];
}

- (instancetype) initWithAudioFormat:(AudioStreamBasicDescription)format
{
	self = [super initWithAudioFormat:format];
	
	if (self)
	{
		[self setupPlaybackAudioQueueObject];
		_stopped = NO;
		_audioPlayerShouldStopImmediately = NO;
		_bufferByteSize = BUFFER_BYTE_SIZE;
	}
	
	return self;
}

- (void) fillBuffer: (void*) buffer
{
}

- (void) setupPlaybackAudioQueueObject
{
	AudioQueueNewOutput (&audioFormat, playbackCallback, (__bridge void *)(self), nil, nil, 0, &queueObject);
	
	AudioQueueSetParameter (queueObject, kAudioQueueParam_Volume, 1.0f);
}

- (void) setupAudioQueueBuffers
{
	// prime the queue with some data before starting
	// allocate and enqueue buffers
	for (int bufferIndex = 0; bufferIndex < NUMBER_AUDIO_DATA_BUFFERS; ++bufferIndex)
	{
		AudioQueueAllocateBuffer (queueObject, _bufferByteSize, &buffers[bufferIndex]);
		
		playbackCallback ((__bridge void *)(self), queueObject, buffers[bufferIndex]);
		
		if (_stopped)
		{
			break;
		}
	}
}

- (void) play
{
	[self setupAudioQueueBuffers];
	
	AudioQueueStart (self.queueObject, NULL);
}

- (void) stop
{
	AudioQueueStop (self.queueObject, self.audioPlayerShouldStopImmediately);
}


- (void) pause
{
	AudioQueuePause (self.queueObject);
}


- (void) resume
{
	AudioQueueStart (self.queueObject, NULL);
}


- (void) dealloc
{
	AudioQueueDispose (queueObject,YES);
}

@end
