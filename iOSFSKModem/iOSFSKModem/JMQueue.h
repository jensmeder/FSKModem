#import <Foundation/Foundation.h>

@interface JMQueue : NSObject

@property (readonly) NSUInteger count;

-(void) enqueueObject:(NSObject*)obj;
-(id) dequeueQbject;

@end
