#import "JMAudioStream.h"
#import "JMPatternRecognizer.h"

typedef struct
{
	int			lastFrame;
	int			lastEdgeSign;
	unsigned	lastEdgeWidth;
	int			edgeSign;
	int			edgeDiff;
	unsigned	edgeWidth;
	unsigned	plateauWidth;
}
JMAnalyzerData;

@interface JMAudioInputStream : JMAudioStream

@property (readwrite) BOOL	stopping;
@property (readonly) JMAnalyzerData* pulseData;

- (void) addRecognizer: (id<JMPatternRecognizer>)recognizer;

- (void) setupRecording;

- (void) record;
- (void) stop;

- (void) edge: (int)height width:(unsigned)width interval:(unsigned)interval;
- (void) idle: (unsigned)samples;
- (void) reset;

@end
