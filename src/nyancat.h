
#import "TelnetServer.h"

#include <ctype.h>
#include <stdint.h>
#include <signal.h>
#include <time.h>
#include <setjmp.h>
#include <getopt.h>
#include <sys/ioctl.h>
#ifndef TIOCGWINSZ
#include <termios.h>
#endif
#ifdef ECHO
#undef ECHO
#endif
/*	telnet.h contains some #defines for the various commands, escape characters, and modes for telnet.
 	(it surprises some people that telnet is, really, a protocol, and not just raw text transmission)	*/
#include "telnet.h"
/*	The animation frames are stored separately in this header so they don't clutter the core source	*/
#include "animation.h"

@interface NyanCat : NSObject
{
/*	Environment to use for setjmp/longjmp when breaking out of options handler */
jmp_buf environment;

}
- (id) initWithArgC:(int)argc argv:(char **)argv;

@property (readonly) NSString *term;
/*	Color palette to use for final output Specifically, this should be either control sequences or raw characters (ie, for vt220 mode)	*/
@property (readonly) char * colors;
/*	For most modes, we output spaces, but for some we will use block characters (or even nothing)  */
@property char *output;
/* Are we currently in telnet mode? */
@property (nonatomic) BOOL inTelnet;
/*	Whether or not to show the counter	*/
@property int show_counter;
/*	Number of frames to show before quitting or 0 to repeat forever (default)	*/
@property int frame_count;
/*	Clear the screen between frames (as opposed to reseting the cursor position) */
@property int clear_screen;
/*	Force-set the terminal title.	*/
@property int set_title;

@end


/*	I refuse to include libm to keep this low on external dependencies.
	 	Count the number of digits in a number for use with string output.	*/
NS_INLINE int digits(int val) {    int d = 1, c;
    if (val >= 0) for (c =  10; c <= val; c *= 10) d++;
    else          for (c = -10; c >= val; c *= 10) d++;  return c < 0 ? ++d : d;
}
