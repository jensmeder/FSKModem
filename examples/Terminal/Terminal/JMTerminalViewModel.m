//
//  JMTerminalViewModel.m
//  Terminal
//
//  Created by Jens Meder on 09.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import "JMTerminalViewModel.h"
#import "JMFSKModem.h"

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
