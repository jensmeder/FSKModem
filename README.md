iOS-FSK-Modem
=============

iOS FSK Modem is a framework that allows data transmission from any iOS devices via the head phone jack. It uses frequency shift keying to modulate a sine curve carrier signal.

## Project setup

If you want to use iOS FSK Modem in your app you need to add the following frameworks to your link library build phase of your project:

* AudioToolbox.framework
* AVFoundation.framework

You can either copy the source code files directly to your project or link the Static Library target of the iOS FSK Modem framework to your project. If you choose the latter one make sure to include the `-lstdc++ -ObjC -all_load` flags to the `Other Linker Flags` build settings of your target / project to avoid linker errors.

## Initial setup

```objc
AVAudioSession* session = [AVAudioSession sharedInstance];
JMFSKModemConfiguration* configuration = [JMModemConfiguration highSpeedConfiguration];
JMFSKModem* modem = [[JMFSKModem alloc]initWithAudioSession:session andConfiguration:configuration];

[modem connect];
```

## Sending data

```objc
NSString* textToSend = @"Hello World";
NSData* dataToSend = [textToSend dataUsingEncoding:NSASCIIStringEncoding];

[modem sendData:dataToSend];
```

##Receiving data

Register a delegate on your `JMFSKModem` instance and implement the `JMFSKModemDelegate` protocol to be notified whenever data arrives.

### Setting the delegate object

```objc
modem.delegate = myModemDelegate;
```

### Delegate implementation

```objc
-(void)modem:(JMFSKModem *)modem didReceiveData:(NSData *)data
{
	NSString* receivedText = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(@"%@", receivedText);
}
```

## Credits / Acknowledgements
