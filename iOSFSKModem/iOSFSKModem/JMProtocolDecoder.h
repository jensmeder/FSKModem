#import <Foundation/Foundation.h>
#import "JMFSKRecognizerDelegate.h"
#import "JMProtocolDecoderDelegate.h"

@interface JMProtocolDecoder : NSObject<JMFSKRecognizerDelegate>

@property (nonatomic, weak) id<JMProtocolDecoderDelegate> delegate;

@end
