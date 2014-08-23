
@import AVFoundation;
@import AtoZ; @import Foundation; @import Darwin;  // needed for winsize, ioctl etc
#import <getopt.h>
#import  <stdio.h>

static BOOL  clear_screen = YES,  //	Clear the screen between frames (as opposed to reseting the cursor position) // IF NO works, but shitty
                   telnet = NO;   //	Are we currently in telnet mode?

FOUNDATION_EXPORT void print_with_newlines ( char *, ...);
FOUNDATION_EXPORT void             newline (  int );
FOUNDATION_EXPORT void        reset_cursor ( void );
FOUNDATION_EXPORT void          clr_screen ( void );

typedef struct zTermSize {    int width;
                              int height; } zTermSize;
#pragma mark COLOR


JREnumDeclare( FMTOptions,

                  FMT_BOLD      = 0x00000001,
                  FMT_UNDL      = 0x00000010,
                  FMT_BLNK      = 0x00000100,
                  FMT_NEG       = 0x00001000,
                  FMT_POS       = 0x00011000,
                  FMT_FRAME     = 0x00100000,
                  FMT_ENCIRCLE  = 0x01000000,
                  FMT_OVERLINED = 0x10000000,
                  FMT_NO_RESET  = 0x11111111
);

@interface NSColor  (atozio)

+ (NSA*) x16; + (NSC*) xColor:(int)x; @prop_ NSC *bg, *fg; - (NSC*) withBG:(NSC*)c; - (NSC*) withFG:(NSC*)c;
@end

@interface NSString (atozio)

+ (INST) withColor:(NSC*)c fmt:(NSS*)fmt,...; @prop_ FMTOptions options; @prop_ NSC * color; @prop_RO CCHAR   xString;  - (void) xPrint;
@end

@interface CALayer (atozio)

@prop_RO CCHAR xString;

@end


//void  zPrint (NSC* fg, NSC*bg, FMTOptions opts, NSS* fmt, ...);

@interface AtoZ (io)

/** -=/><\=-=/><\=-=/><\=-=/><\=-=/><\=-=/><\=-=/><\=-=/><\=-=/><\=-
 Returns the embbedded data for the CURRENT executable from a specific section in a specific segment.
    Segment is %SPECIFIED% Section is %SPECIFIED%
	@param segment a segment with the |section| to get data from
	@param section a section to get data from
	@param error if a parsing error occurs and nil is returned, this is the NSError that occured
	@return a NSDictionary or nil
 */
+ (NSData*)embeddedDataFromSegment:(NSS*)seg inSection:(NSS*)sec error:(NSERR**)e;

+ (AVAudioPlayer*) playerForAudio:(id)dataOrPath;
+ (zTermSize) terminalSize;
+       (int) terminal_width;
+       (int) terminal_height;

+ (NSD*)parseArgs:(char *[])argv andKeys:(NSArray*)keys count:(int)argc;

//+ (NSURL*) namePipe:(NSS*)path withData:(NSData*)d;
@end


/*!	char **argv = *_NSGetArgv();
    NSString *commandLineArg = sizeof(argv) > 1 && !!argv[1] ? @(argv[1])
                                                             : @"/tmp/scorecard-pipe";  // No argument specified, using xyz
*/ extern char ***_NSGetArgv (void);
   extern int     _NSGetArgc (void);

/*! mkfifo @code

  NSString *pipePath = @"..."

  if ( mkfifo(pipePath.UTF8String, 0666) == -1 && errno !=EEXIST)	NSLog(@"Unable to open the named pipe %@", pipePath);
	
	int fd = open(pipePath.UTF8String, O_RDWR | O_NDELAY);

	filehandleForReading = [NSFileHandle.alloc initWithFileDescriptor:fd closeOnDealloc: YES];

	[NSNotificationCenter.defaultCenter     removeObserver:self];
	[NSNotificationCenter.defaultCenter addObserverForName:NSFileHandleReadCompletionNotification
                                                  object:filehandleForReading queue:NSOperationQueue.mainQueue
                                              usingBlock:^(NSNotification *n) {

    NSData *d = n.userInfo[NSFileHandleNotificationDataItem];

    if (d.length) {
      NSLog(@"dataReady:%lu bytes", d.length);
      /// .... NSString * dataString = [NSString.alloc initWithData:d encoding:NSASCIIStringEncoding];
    }
    [filehandleForReading readInBackgroundAndNotify]; //Tell the fileHandler to asychronusly report back

  }];

	[filehandleForReading readInBackgroundAndNotify];
*/
extern int         mkfifo (const char *, mode_t);


#define CHAR_FMT(...) [NSString stringWithFormat:@__VA_ARGS__].UTF8String

char term[1024] = {'a','n','s','i', 0};  /* The default terminal is ANSI */

/*	I refuse to include libm to keep this low on external dependencies. Count the number of digits in a number for use with string output.	*/

NS_INLINE int digits(int val){

  int d = 1,c; val >= 0 ? ({ for (c =  10; c <= val; c *= 10) d++; }) : ({ for (c = -10; c >= val; c *= 10) d++; });  return c < 0 ? ++d : d;
}

//@interface AtoZOption : NSObject
//@property NSS* name;
//@end

//void       ClrPlus (const char* c);
//void    PrintInClr (const char* s, zColor c);
//void      PrintClr (zColor c);
//void SystemGrays ();
//void    System16 ();
//void FillScreen(zColor c);
//void   Spectrum();
//void   AllColors(void(^block)(zColor c));
//void PrintInRnd(id x,...);
//typedef    int zColor;
//typedef RgbColor zColorRGB;
//typedef struct zColorRGB { zColor r;
//                           zColor g;
//                           zColor b; } zColorRGB;

//int      rgb_to_xterm ( NSC*);
