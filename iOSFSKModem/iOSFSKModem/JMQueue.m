#import "JMQueue.h"
#import "JMQueueNode.h"

@implementation JMQueue
{
	@private
	
	JMQueueNode* _firstNode;
	JMQueueNode* _lastNode;
	
	dispatch_queue_t _queue;
}

-(instancetype)init
{
	self = [super init];
	
	if (self)
	{
		_queue = dispatch_queue_create("de.jensmeder.concurrencyQueue", DISPATCH_QUEUE_CONCURRENT);
	}
	
	return self;
}

-(void)enqueueObject:(NSObject *)obj
{
	dispatch_barrier_async(_queue,
	^{
		JMQueueNode* node = [[JMQueueNode alloc]initWithObject:obj];
	
		if (_count == 0)
		{
			_firstNode = node;
		}
		else
		{
			_lastNode.next = node;
		}
	
		_lastNode = node;
		_count++;
	});
}

-(id)dequeueQbject
{
	if (_count == 0)
	{
		return nil;
	}
	
	__block JMQueueNode* node = nil;
	dispatch_sync(_queue,
	^{
		node = _firstNode;
	
		if(_count == 1)
		{
			_firstNode = nil;
			_lastNode = nil;
		}
		else if (_count == 2)
		{
			_firstNode = _lastNode;
		}
		else
		{
			_firstNode = node.next;
		}
	
		_count--;
	});
	
	return node.object;
}

@end
