#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>

@class JMFSKModem;

@protocol JMFSKModemDelegate <NSObject>

-(void) modem:(JMFSKModem *)modem didReceiveData:(NSData*)data;

@end

@interface JMFSKModem : NSObject

@property (nonatomic, weak) id<JMFSKModemDelegate> delegate;
@property (readonly) BOOL connected;

-(instancetype)initWithAudioSession:(AVAudioSession*)audioSession;

-(void) connect;
-(void) disconnect;

-(void) sendData:(NSData*)data;

@end
