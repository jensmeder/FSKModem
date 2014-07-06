#import "JMAudioSource.h"
#import <AudioToolbox/AudioToolbox.h>
#import "JMModemConfiguration.h"

@interface JMFSKSerialGenerator : NSObject<JMAudioSource>

- (instancetype) initWithAudioFormat:(AudioStreamBasicDescription*)audioFormat configuration:(JMModemConfiguration*)configuration;

- (void) writeData:(NSData*)data;

@end
