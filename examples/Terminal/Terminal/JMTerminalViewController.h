//
//  JMTerminalViewController.h
//  Terminal
//
//  Created by Jens Meder on 09.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JMTerminalViewModel;

@interface JMTerminalViewController : UIViewController

-(instancetype)initWithViewModel:(JMTerminalViewModel*)viewModel;

@end
