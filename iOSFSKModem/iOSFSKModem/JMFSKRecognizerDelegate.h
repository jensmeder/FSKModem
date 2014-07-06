@class JMFSKRecognizer;

@protocol JMFSKRecognizerDelegate

- (void) recognizer:(JMFSKRecognizer*)recognizer didReceiveByte:(UInt8)input;

@end