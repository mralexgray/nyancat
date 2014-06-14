//
//  atozio.h
//  atozio
//
//  Created by Alex Gray on 6/13/14.
//  Copyright (c) 2014 Alex Gray. All rights reserved.
//

@import AtoZ;
@import Foundation; @import Darwin;  // needed for winsize, ioctl etc
@import AVFoundation;

#import <AQOptionParser.h>

/*	I refuse to include libm to keep this low on external dependencies.
	 	Count the number of digits in a number for use with string output.	*/
NS_INLINE int digits(int val){ int d = 1,c; val >= 0 ? ({ for (c =  10; c <= val; c *= 10) d++; }) : ({ for (c = -10; c >= val; c *= 10) d++; });  return c < 0 ? ++d : d; }


@interface AtoZOption : NSObject
@property NSS* name;
@end

#define CHAR_FMT(...) [NSString stringWithFormat:@__VA_ARGS__].UTF8String

char term[1024] = {'a','n','s','i', 0};  /* The default terminal is ANSI */

static BOOL  clear_screen = YES,  //	Clear the screen between frames (as opposed to reseting the cursor position) // IF NO works, but shitty
                   telnet = NO;   //	Are we currently in telnet mode?

FOUNDATION_EXPORT void print_with_newlines(char *first,...);
FOUNDATION_EXPORT void             newline(int n);
FOUNDATION_EXPORT void        reset_cursor(void);
FOUNDATION_EXPORT void          clr_screen(void);

typedef struct zTermSize { int width; int height; } zTermSize;

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
+ (int) terminal_width;
+ (int) terminal_height;

+ (NSD*)parseArgs:(char *[])argv andKeys:(NSArray*)keys count:(int)argc;

@end
