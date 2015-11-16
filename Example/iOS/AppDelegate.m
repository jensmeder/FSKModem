//
//  AppDelegate.m
//  iOS Example
//
//  Created by Jens Meder on 16/11/15.
//  Copyright © 2015 Jens Meder. All rights reserved.
//

#import "AppDelegate.h"

#import <FSKModem/JMFSKModem.h>

@interface AppDelegate () <JMFSKModemDelegate>

@end

@implementation AppDelegate
{
	@private
	
	JMFSKModem* _modem;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	
	_modem = [[JMFSKModem alloc]initWithConfiguration:[JMFSKModemConfiguration mediumSpeedConfiguration]];
	_modem.delegate = self;
	[_modem connect:^(BOOL error) {
		NSData* data = [@"Hello World" dataUsingEncoding:NSUTF8StringEncoding];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[_modem sendData:data];
		});
		
	}];
	
	
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
