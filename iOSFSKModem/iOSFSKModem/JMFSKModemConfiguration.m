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

#import "JMFSKModemConfiguration.h"

@implementation JMFSKModemConfiguration

-(instancetype)initWithBaudRate:(UInt16)baudRate lowFrequency:(UInt16)lowFrequency highFrequency:(UInt16)highFrequency
{
	self = [super init];
	
	if (self)
	{
		_baudRate = baudRate;
		_highFrequency = highFrequency;
		_lowFrequency = lowFrequency;
		
		_highFrequencyWaveDuration = (double) NSEC_PER_SEC / (double) _highFrequency;
		_lowFrequencyWaveDuration = (double) NSEC_PER_SEC / (double) _lowFrequency;
		_bitDuration = (double) NSEC_PER_SEC / _baudRate;
	}
	
	return self;
}

+(JMFSKModemConfiguration *)lowSpeedConfiguration
{
	return [[JMFSKModemConfiguration alloc]initWithBaudRate:100 lowFrequency:800 highFrequency:1600];
}

+(JMFSKModemConfiguration *)mediumSpeedConfiguration
{
	return [[JMFSKModemConfiguration alloc]initWithBaudRate:600 lowFrequency:2666 highFrequency:4000];
}

+(JMFSKModemConfiguration *)highSpeedConfiguration
{
	return [[JMFSKModemConfiguration alloc]initWithBaudRate:1225 lowFrequency:4900 highFrequency:7350];
}

@end
