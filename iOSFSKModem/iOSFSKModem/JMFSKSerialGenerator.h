#import "JMAudioSource.h"
#import <AudioToolbox/AudioToolbox.h>

@interface JMFSKSerialGenerator : NSObject<JMAudioSource>

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription*)audioFormat;

- (void) writeData:(NSData*)data;

@end
