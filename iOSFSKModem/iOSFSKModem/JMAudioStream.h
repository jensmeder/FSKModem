#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>

@interface JMAudioStream : NSObject
{
	@protected

	AudioQueueRef queueObject;
	AudioStreamBasicDescription	audioFormat;
}

@property (readwrite) AudioQueueRef	queueObject;
@property (readwrite) AudioStreamBasicDescription audioFormat;

@property (NS_NONATOMIC_IOSONLY, getter=isRunning, readonly) BOOL running;

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription)format;

@end
