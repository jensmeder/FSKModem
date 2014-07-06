@class JMAudioOutputStream;

@protocol JMAudioSource <NSObject>

-(void) outputStream:(JMAudioOutputStream*)stream fillBuffer:(void*)buffer bufferSize:(NSUInteger)bufferSize;

@end
