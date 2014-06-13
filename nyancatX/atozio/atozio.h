//
//  atozio.h
//  atozio
//
//  Created by Alex Gray on 6/13/14.
//  Copyright (c) 2014 Alex Gray. All rights reserved.
//

@import AtoZ;
@import Foundation; @import Darwin;  // needed for winsize, ioctl etc

#import <AQOptionParser.h>


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


typedef struct zTermSize { int width; int height; } zTermSize;

@interface AtoZ (io)

+ (zTermSize) terminalSize;
+ (int) terminal_width;
+ (int) terminal_height;

+ (NSD*)parseArgs:(char *[])argv andKeys:(NSArray*)keys count:(int)argc;

@end
