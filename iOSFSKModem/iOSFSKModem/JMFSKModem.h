#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>
#import "JMModemConfiguration.h"

@class JMFSKModem;

@protocol JMFSKModemDelegate <NSObject>

-(void) modem:(JMFSKModem *)modem didReceiveData:(NSData*)data;

@end

@interface JMFSKModem : NSObject

@property (nonatomic, weak) id<JMFSKModemDelegate> delegate;
@property (readonly) BOOL connected;

-(instancetype)initWithAudioSession:(AVAudioSession*)audioSession andConfiguration:(JMModemConfiguration*)configuration;

-(void) connect;
-(void) disconnect;

-(void) sendData:(NSData*)data;

@end
