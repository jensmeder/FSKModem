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

#import "JMFSKModem.h"
#import "JMAudioInputStream.h"
#import "JMFSKSerialGenerator.h"
#import "JMAudioOutputStream.h"
#import "JMAudioInputStream.h"
#import "JMFSKRecognizer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "JMProtocolDecoder.h"
#import "JMProtocolDecoderDelegate.h"
#import "JMProtocolEncoder.h"

static const int SAMPLE_RATE = 44100;

static const int NUM_CHANNELS = 1;
static const int BITS_PER_CHANNEL = 16;
static const int BYTES_PER_FRAME = (NUM_CHANNELS * (BITS_PER_CHANNEL / 8));

@interface JMFSKModem () <JMProtocolDecoderDelegate>

@end

@implementation JMFSKModem
{
	@private
	
	JMFSKModemConfiguration* _configuration;
	AudioStreamBasicDescription* _audioFormat;
	
	JMAudioInputStream* _inputStream;
	JMAudioOutputStream* _outputStream;
	JMFSKSerialGenerator* _generator;
	JMProtocolDecoder* _decoder;
	JMProtocolEncoder* _encoder;
	
	dispatch_once_t _setupToken;
}

-(instancetype)initWithConfiguration:(JMFSKModemConfiguration *)configuration
{
	self = [super init];
	
	if (self)
	{
		_configuration = configuration;
	}
	
	return self;
}

-(void)dealloc
{
	[self disconnect:NULL];
	
	if (_audioFormat)
	{
		delete _audioFormat;
	}
}

-(void) setupAudioFormat
{
	_audioFormat = new AudioStreamBasicDescription();
		
	_audioFormat->mSampleRate = SAMPLE_RATE;
	_audioFormat->mFormatID	= kAudioFormatLinearPCM;
	_audioFormat->mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	_audioFormat->mFramesPerPacket = 1;
	_audioFormat->mChannelsPerFrame	= NUM_CHANNELS;
	_audioFormat->mBitsPerChannel = BITS_PER_CHANNEL;
	_audioFormat->mBytesPerPacket = BYTES_PER_FRAME;
	_audioFormat->mBytesPerFrame = BYTES_PER_FRAME;
}

-(void) setup
{
	__weak typeof(self) weakSelf = self;

	dispatch_once(&_setupToken,
	^{
		__strong typeof(weakSelf) strongSelf = weakSelf;
	
		[strongSelf setupAudioFormat];
		
		strongSelf->_encoder = [[JMProtocolEncoder alloc]init];
		
		strongSelf->_outputStream = [[JMAudioOutputStream alloc]initWithAudioFormat:*_audioFormat];
	
		strongSelf->_inputStream = [[JMAudioInputStream alloc]initWithAudioFormat:*_audioFormat];
		strongSelf->_generator = [[JMFSKSerialGenerator alloc]initWithAudioFormat:strongSelf->_audioFormat configuration:strongSelf->_configuration];
		strongSelf->_outputStream.audioSource = _generator;
		
		strongSelf->_decoder = [[JMProtocolDecoder alloc]init];
		strongSelf->_decoder.delegate = self;
		
		JMFSKRecognizer* recognizer = [[JMFSKRecognizer alloc]initWithConfiguration:strongSelf->_configuration];
		recognizer.delegate = _decoder;
		
		[strongSelf->_inputStream addRecognizer:recognizer];
	});
}

-(void)connect
{
	[self connect:NULL];
}

-(void)connect:(void (^)(BOOL error))completion
{
	if (!_connected)
	{
		__weak typeof(self) weakSelf = self;

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
		^{
			__strong typeof(weakSelf) strongSelf = weakSelf;
			
			[strongSelf setup];
		
#if TARGET_OS_IPHONE
		
			if([AVAudioSession sharedInstance].availableInputs.count > 0)
			{
				[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
				[strongSelf->_inputStream record];
			}
			else
			{
				[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
			}
		
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
		
			NSError* error = nil;
			[[AVAudioSession sharedInstance] setActive:YES error:&error];
			
			if (error)
			{
				if (completion)
				{
					completion(YES);
				}
				dispatch_async(dispatch_get_main_queue(),
				^{
					[strongSelf->_delegate modemDidDisconnect:strongSelf];
				});

				return;
			}
#endif
	
			[strongSelf->_outputStream play];
		
			strongSelf->_connected = YES;
			
			if (completion)
			{
				completion(NO);
			}
			dispatch_async(dispatch_get_main_queue(),
			^{
				[strongSelf->_delegate modemDidConnect:strongSelf];
			});
		});
	}
}

-(void)disconnect
{
	[self disconnect:NULL];
}

-(void)disconnect:(void (^)(BOOL error))completion
{
	if (_connected)
	{
		__weak typeof(self) weakSelf = self;

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
		^{
			__strong typeof(weakSelf) strongSelf = weakSelf;
		
			[strongSelf->_inputStream stop];
			[strongSelf->_outputStream stop];
		
#if TARGET_OS_IPHONE

			[[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
		
			NSError* error = nil;
			[[AVAudioSession sharedInstance] setActive:NO error:&error];
			
			if (error)
			{
				if (completion)
				{
					completion(YES);
				}
				
				dispatch_async(dispatch_get_main_queue(),
				^{
					[strongSelf->_delegate modemDidConnect:strongSelf];
				});
				
				return;
			}
#endif
	
			strongSelf->_connected = NO;
			
			if (completion)
			{
				completion(NO);
			}
			
			dispatch_async(dispatch_get_main_queue(),
			^{
				[strongSelf->_delegate modemDidDisconnect:strongSelf];
			});
		});
	}
}

-(void)sendData:(NSData *)data
{
	if (_connected)
	{
		[_generator writeData:[_encoder encodeData:data]];
	}
}

#pragma mark - Protocol decoder delegate

-(void)decoder:(JMProtocolDecoder *)decoder didDecodeData:(NSData *)data
{
	[_delegate modem:self didReceiveData:data];
}

#pragma mark - Notifications

- (void)routeChanged:(NSNotification*)notification
{
	if (_connected)
	{
		[self disconnect:NULL];
	
		[self connect:NULL];
	}
}

@end
