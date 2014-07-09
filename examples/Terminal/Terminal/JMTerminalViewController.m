//
//  JMTerminalViewController.m
//  Terminal
//
//  Created by Jens Meder on 09.07.14.
//  Copyright (c) 2014 Jens Meder. All rights reserved.
//

#import "JMTerminalViewController.h"
#import "JMTerminalView.h"
#import "JMTerminalViewModel.h"

@interface JMTerminalViewController () <UITextFieldDelegate>

@end

@implementation JMTerminalViewController
{
	@private
	
	JMTerminalViewModel* _viewModel;
}

-(instancetype)initWithViewModel:(JMTerminalViewModel *)viewModel
{
	self = [super init];
	
	if (self)
	{
		_viewModel = viewModel;
	}
	
	return self;
}

-(void)loadView
{
	self.view = [[JMTerminalView alloc]init];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	JMTerminalView* terminalView = (JMTerminalView*)self.view;
	
	terminalView.inputTextField.delegate = self;
	
	[_viewModel addObserver:self forKeyPath:@"receivedText" options:NSKeyValueObservingOptionNew context:NULL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	JMTerminalView* terminalView = (JMTerminalView*)self.view;
	
	terminalView.inputTextField.delegate = nil;
	
	[_viewModel removeObserver:self forKeyPath:@"receivedText"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void) keyboardFrameWillChange:(NSNotification*)notification
{
	UIViewAnimationCurve curve = [((NSNumber*)[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]) integerValue];
	float duration = [((NSNumber*)[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]) floatValue];
	CGRect endFrame = [((NSValue*)[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]) CGRectValue];
	
	[UIView beginAnimations:@"" context:NULL];
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:duration];
	
	CGRect frame = self.view.frame;
	
	self.view.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, endFrame.origin.y);
	[self.view layoutIfNeeded];
	[UIView commitAnimations];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	JMTerminalView* terminalView = (JMTerminalView*)self.view;
	
	terminalView.receivingTextView.text = _viewModel.receivedText;
}

#pragma mark - Text field delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[_viewModel sendMessage:textField.text];
	textField.text = nil;

	return NO;
}

@end
