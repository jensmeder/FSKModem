#import "JMPatternRecognizer.h"
#import "JMFSKRecognizerDelegate.h"
#import "JMModemConfiguration.h"

@interface JMFSKRecognizer : NSObject <JMPatternRecognizer>

@property (nonatomic, weak) NSObject<JMFSKRecognizerDelegate>* delegate;

-(instancetype)initWithConfiguration:(JMModemConfiguration*)configuration;

- (void) edge: (int)height width:(UInt64)nsWidth interval:(UInt64)nsInterval;
- (void) idle: (UInt64)nsInterval;
- (void) reset;

@end
