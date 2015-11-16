//	The MIT License (MIT)
//
//	Copyright (c) 2014 Jens Meder
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

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
