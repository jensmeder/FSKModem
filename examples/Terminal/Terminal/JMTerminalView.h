//
//  JMTerminalView.h
//  Terminal
//
//  Created by Jens Meder on 09.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JMTerminalView : UIView

@property (nonatomic, strong, readonly) UITextField* inputTextField;
@property (nonatomic, strong, readonly) UITextView* receivingTextView;

@end
