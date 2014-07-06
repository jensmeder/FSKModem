#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>

@interface JMAudioStream : NSObject
{
	@protected

	AudioQueueRef queueObject;
	AudioStreamBasicDescription	audioFormat;
}

@property (readonly) AudioQueueRef	queueObject;
@property (readonly) AudioStreamBasicDescription audioFormat;

@property (NS_NONATOMIC_IOSONLY, getter=isRunning, readonly) BOOL running;

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription)format;

@end
