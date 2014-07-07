iOS-FSK-Modem
=============

The iOS FSK Modem framework allows sending and receiving data from any iOS devices via the head phone jack. It uses frequency shift keying (FSK) to modulate a sine curve carrier signal to transmit bits. On top of that it uses a serial protocol to transmit single bytes and a simple packet protocol to cluster bytes. 

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
## Talking to Arduino



## Credits / Acknowledgements

This project uses code from arm22's SoftModemTerminal application.

https://code.google.com/p/arms22/wiki/SoftModemBreakoutBoard

The guys from Perceptive Development provide a great read on their usage of FSK in the Tin Can iOS App.

http://labs.perceptdev.com/how-to-talk-to-tin-can/
