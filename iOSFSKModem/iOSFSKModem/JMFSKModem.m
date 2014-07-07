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
	
	AVAudioSession* _audioSession;
	JMFSKModemConfiguration* _configuration;
	AudioStreamBasicDescription* _audioFormat;
	
	JMAudioInputStream* _inputStream;
	JMAudioOutputStream* _outputStream;
	JMFSKSerialGenerator* _generator;
	JMProtocolDecoder* _decoder;
	JMProtocolEncoder* _encoder;
	
	dispatch_once_t _setupToken;
}

-(instancetype)initWithAudioSession:(AVAudioSession *)audioSession andConfiguration:(JMFSKModemConfiguration *)configuration
{
	self = [super init];
	
	if (self)
	{
		_audioSession = audioSession;
		_configuration = configuration;
	}
	
	return self;
}

-(void)dealloc
{
	[self disconnect];
	
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
	
		[strongSelf->_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
		[strongSelf->_audioSession setActive:YES error:nil];
		
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
	if (!_connected)
	{
		[self setup];
		
		if(_audioSession.availableInputs.count > 0)
		{
			[_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
			[_inputStream record];
		}
		else
		{
			[_audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
		}
	
		[_outputStream play];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
	
		_connected = YES;
	}
}

-(void)disconnect
{
	if (_connected)
	{
		[_inputStream stop];
		[_outputStream stop];

		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
	
		_connected = NO;
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
		[self disconnect];
	
		[self connect];
	}
}

@end
