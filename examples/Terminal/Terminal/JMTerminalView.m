//
//  JMTerminalView.m
//  Terminal
//
//  Created by Jens Meder on 09.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import "JMTerminalView.h"

@implementation JMTerminalView

- (instancetype)init
{
    self = [super init];
	
    if (self)
	{
		self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        _inputTextField = [[UITextField alloc]init];
		_inputTextField.borderStyle = UITextBorderStyleRoundedRect;
		_inputTextField.translatesAutoresizingMaskIntoConstraints = NO;
		[_inputTextField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
		
		_receivingTextView = [[UITextView alloc]init];
		_receivingTextView.backgroundColor = [UIColor whiteColor];
		_receivingTextView.translatesAutoresizingMaskIntoConstraints = NO;
		_receivingTextView.editable = NO;
		_receivingTextView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);

		[self addSubview:_receivingTextView];
		[self addSubview:_inputTextField];
		
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_receivingTextView]-5-[_inputTextField(35)]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_inputTextField, _receivingTextView)]];
	
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_receivingTextView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_receivingTextView)]];
	
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[_inputTextField]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_inputTextField)]];
    }
	
    return self;
}

@end
