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

#import <AudioToolbox/AudioToolbox.h>
#import "JMAudioOutputStream.h"

static const int NUMBER_AUDIO_DATA_BUFFERS = 3;
static const int BUFFER_BYTE_SIZE = 1024;

@interface JMAudioOutputStream ()

@property (readonly) AudioStreamPacketDescription* packetDescriptions;
@property (readonly) BOOL stopped;
@property (readonly) BOOL audioPlayerShouldStopImmediately;
@property (readonly) UInt32 bufferByteSize;
@property (readonly) UInt32	bufferPacketCount;

@end


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

- (void) setupPlaybackAudioQueueObject
{
	AudioQueueNewOutput (&_audioFormat, playbackCallback, (__bridge void *)(self), nil, nil, 0, &_queueObject);
	
	AudioQueueSetParameter (_queueObject, kAudioQueueParam_Volume, 1.0f);
}

- (void) setupAudioQueueBuffers
{
	// prime the queue with some data before starting
	// allocate and enqueue buffers
	for (int bufferIndex = 0; bufferIndex < NUMBER_AUDIO_DATA_BUFFERS; ++bufferIndex)
	{
		AudioQueueAllocateBuffer (_queueObject, _bufferByteSize, &buffers[bufferIndex]);
		
		playbackCallback ((__bridge void *)(self), _queueObject, buffers[bufferIndex]);
		
		if (_stopped)
		{
			break;
		}
	}
}

- (void) play
{
	[self setupAudioQueueBuffers];
	
	AudioQueueStart (_queueObject, NULL);
}

- (void) stop
{
	AudioQueueStop (_queueObject, self.audioPlayerShouldStopImmediately);
}


- (void) pause
{
	AudioQueuePause (_queueObject);
}


- (void) resume
{
	AudioQueueStart (_queueObject, NULL);
}


- (void) dealloc
{
	AudioQueueDispose (_queueObject,YES);
}

@end
