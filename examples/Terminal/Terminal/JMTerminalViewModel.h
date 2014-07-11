//
//  JMTerminalViewModel.h
//  Terminal
//
//  Created by Jens Meder on 09.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JMFSKModem;

@interface JMTerminalViewModel : NSObject

@property (nonatomic, strong, readonly) NSString* receivedText;

-(instancetype)initWithModem:(JMFSKModem*)modem;

-(void) sendMessage:(NSString*)message;
-(void) connect;
-(void) disconnect;

@end
