#import "JMProtocolDecoder.h"

static const UInt8 START_BYTE = 0xFF;
static const UInt8 ESCAPE_BYTE = 0x33;
static const UInt8 END_BYTE = 0x77;

@implementation JMProtocolDecoder
{
	@private
	
	NSMutableData* _data;
	BOOL _escaped;
}

-(void)recognizer:(JMFSKRecognizer *)recognizer didReceiveByte:(UInt8)input
{
    if(_escaped)
    {
      [_data appendBytes:&input length:1];
      _escaped = NO;
      
      return;
    }
    
    if(input == ESCAPE_BYTE)
    {
      _escaped = YES;
      
      return;
    }
    
    if(input == START_BYTE)
    {
       _data = [NSMutableData data];
		
	   return;
    }
    
    if(input == END_BYTE)
    {
		if ([_delegate respondsToSelector:@selector(decoder:didDecodeData:)])
		{
			[_delegate decoder:self didDecodeData:_data];
		}
		_data = nil;
		
		return;
    }
    
    [_data appendBytes:&input length:1];
}

@end
