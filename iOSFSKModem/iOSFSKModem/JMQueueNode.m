#import "JMQueueNode.h"

@implementation JMQueueNode
{
	@private
	
	NSObject* _object;
}

-(instancetype)initWithObject:(NSObject *)object
{
	self = [super init];
	
	if (self)
	{
		_object = object;
	}
	
	return self;
}

-(NSObject *)object
{
	return _object;
}

@end
