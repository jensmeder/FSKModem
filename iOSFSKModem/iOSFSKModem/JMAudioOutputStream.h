#import "JMAudioStream.h"
#import "JMAudioSource.h"


@interface JMAudioOutputStream : JMAudioStream

@property (readwrite) AudioStreamPacketDescription	*packetDescriptions;
@property (readwrite) BOOL							stopped, audioPlayerShouldStopImmediately;
@property (readwrite) UInt32						bufferByteSize;
@property (readwrite) UInt32						bufferPacketCount;
@property (nonatomic, strong) id<JMAudioSource> audioSource;

- (void) setupPlaybackAudioQueueObject;
- (void) setupAudioQueueBuffers;

- (void) play;
- (void) stop;
- (void) pause;
- (void) resume;

- (void) fillBuffer:(void*)buffer; 

@end
