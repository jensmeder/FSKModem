#import "JMPatternRecognizer.h"
#import "JMFSKRecognizerDelegate.h"

@interface JMFSKRecognizer : NSObject <JMPatternRecognizer>

@property (nonatomic, weak) NSObject<JMFSKRecognizerDelegate>* delegate;

- (void) edge: (int)height width:(UInt64)nsWidth interval:(UInt64)nsInterval;
- (void) idle: (UInt64)nsInterval;
- (void) reset;

@end
