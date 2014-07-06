#import "JMAudioStream.h"


@implementation JMAudioStream

@synthesize queueObject;
@synthesize audioFormat;

-(instancetype)initWithAudioFormat:(AudioStreamBasicDescription)format
{
	self = [super init];
	
	if (self)
	{
		audioFormat = format;
	}
	
	return self;
}

- (BOOL) isRunning
{	
	UInt32		isRunning;
	UInt32		propertySize = sizeof (UInt32);
	OSStatus	result;
	
	result =	AudioQueueGetProperty (queueObject, kAudioQueueProperty_IsRunning, &isRunning, &propertySize);
	
	if (result != noErr)
	{
		return false;
	}
	
	return isRunning;
}


@end
