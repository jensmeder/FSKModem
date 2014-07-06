#import <Foundation/Foundation.h>

@interface JMQueueNode : NSObject

@property (nonatomic, strong) NSObject* object;
@property (nonatomic, strong) JMQueueNode* next;

-(instancetype)initWithObject:(NSObject*)object;

@end
