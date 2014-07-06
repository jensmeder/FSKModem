@class JMProtocolDecoder;

@protocol JMProtocolDecoderDelegate <NSObject>

-(void) decoder:(JMProtocolDecoder*)decoder didDecodeData:(NSData*)data;

@end