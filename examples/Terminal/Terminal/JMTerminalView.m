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
