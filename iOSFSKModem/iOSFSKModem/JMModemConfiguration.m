//
//  JMModemConfiguration.m
//  iOSFSKModem
//
//  Created by Jens Meder on 06.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import "JMModemConfiguration.h"

@implementation JMModemConfiguration

-(instancetype)initWithBaudRate:(UInt16)baudRate lowFrequency:(UInt16)lowFrequency highFrequency:(UInt16)highFrequency
{
	self = [super init];
	
	if (self)
	{
		_baudRate = baudRate;
		_highFrequency = highFrequency;
		_lowFrequency = lowFrequency;
	}
	
	return self;
}

+(JMModemConfiguration *)lowSpeedConfiguration
{
	return [[JMModemConfiguration alloc]initWithBaudRate:100 lowFrequency:800 highFrequency:1600];
}

+(JMModemConfiguration *)mediumSpeedConfiguration
{
	return [[JMModemConfiguration alloc]initWithBaudRate:600 lowFrequency:2666 highFrequency:4000];
}

+(JMModemConfiguration *)highSpeedConfiguration
{
	return [[JMModemConfiguration alloc]initWithBaudRate:1225 lowFrequency:4900 highFrequency:7350];
}

@end
