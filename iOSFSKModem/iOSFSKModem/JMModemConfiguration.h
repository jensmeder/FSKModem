//
//  JMModemConfiguration.h
//  iOSFSKModem
//
//  Created by Jens Meder on 06.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMModemConfiguration : NSObject

@property (readonly) UInt16 highFrequency;
@property (readonly) UInt16 lowFrequency;
@property (readonly) UInt16 baudRate;

+(JMModemConfiguration*)lowSpeedConfiguration;
+(JMModemConfiguration*)mediumSpeedConfiguration;
+(JMModemConfiguration*)highSpeedConfiguration;

@end
