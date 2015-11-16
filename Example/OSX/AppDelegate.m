//
//  AppDelegate.m
//  OSX Example
//
//  Created by Jens Meder on 16/11/15.
//  Copyright © 2015 Jens Meder. All rights reserved.
//

#import "AppDelegate.h"

#import <FSKModem/JMFSKModem.h>

@interface AppDelegate () <JMFSKModemDelegate>

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
	@private
	
	JMFSKModem* _modem;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	
	_modem = [[JMFSKModem alloc]initWithConfiguration:[JMFSKModemConfiguration mediumSpeedConfiguration]];
	_modem.delegate = self;
	[_modem connect:^(BOOL error) {
		NSData* data = [@"Hello World" dataUsingEncoding:NSUTF8StringEncoding];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[_modem sendData:data];
		});
	}];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

#pragma mark - Delegate

-(void)modem:(JMFSKModem *)modem didReceiveData:(NSData *)data
{
	NSLog(@"%@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
}

-(void)modemDidConnect:(JMFSKModem *)modem
{
	
}

-(void)modemDidDisconnect:(JMFSKModem *)modem
{
	
}

@end
