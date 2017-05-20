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

#import "JMTerminalViewModel.h"

@interface JMTerminalViewModel ()<JMFSKModemDelegate>

@end

@implementation JMTerminalViewModel
{
	@private
	
	JMFSKModem* _modem;
}

-(instancetype)initWithModem:(JMFSKModem *)modem
{
	self = [super init];

	if (self)
	{
		_modem = modem;
		_modem.delegate = self;
		_receivedText = @"";
	}

	return self;
}

-(void)sendMessage:(NSString *)message
{
	NSData* data = [message dataUsingEncoding:NSASCIIStringEncoding];
	
	[_modem sendData:data];
}

-(void)connect
{
	[_modem connect];
}

-(void)disconnect
{
	[_modem disconnect];
}

-(void)setConnected:(BOOL)connected
{
	[self willChangeValueForKey:@"connected"];
	
	_connected = connected;
	
	[self didChangeValueForKey:@"connected"];
}

#pragma mark - Delegate

-(void)modem:(JMFSKModem *)modem didReceiveData:(NSData *)data
{
	NSString* text = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
	
	[self willChangeValueForKey:@"receivedText"];
	
	_receivedText = [_receivedText stringByAppendingFormat:@"%@\n",text];
	
	[self didChangeValueForKey:@"receivedText"];
}

-(void)modemDidDisconnect:(JMFSKModem *)modem
{
	[self setConnected:NO];
}

-(void)modemDidConnect:(JMFSKModem *)modem
{
	[self setConnected:YES];
}

@end
