//
//  AppDelegate.m
//  Terminal
//
//  Created by Jens Meder on 09.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import "AppDelegate.h"
#import "JMTerminalViewController.h"
#import "JMTerminalViewModel.h"
#import "JMFSKModem.h"

@implementation AppDelegate
{
	@private
	
	UIWindow* _mainWindow;
	JMTerminalViewController* _terminalViewController;
	JMFSKModem* _modem;
}
            

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	_modem = [[JMFSKModem alloc]initWithConfiguration:[JMFSKModemConfiguration highSpeedConfiguration]];
	JMTerminalViewModel* terminalViewModel = [[JMTerminalViewModel alloc]initWithModem:_modem];
	_terminalViewController = [[JMTerminalViewController alloc]initWithViewModel:terminalViewModel];

	_mainWindow = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
	_mainWindow.rootViewController = _terminalViewController;
	[_mainWindow makeKeyAndVisible];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[_modem disconnect];
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
	[_modem connect];
}

@end
