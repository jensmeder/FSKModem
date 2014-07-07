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
