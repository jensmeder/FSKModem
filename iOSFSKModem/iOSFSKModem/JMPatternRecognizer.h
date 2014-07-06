#import <Foundation/Foundation.h>


@protocol JMPatternRecognizer <NSObject>

- (void) edge: (int)height width:(UInt64)nsWidth interval:(UInt64)nsInterval;
- (void) idle: (UInt64)nsInterval;
- (void) reset;

@end
