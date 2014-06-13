//
//  atozio.m
//  atozio
//
//  Created by Alex Gray on 6/13/14.
//  Copyright (c) 2014 Alex Gray. All rights reserved.
//

#import "atozio.h"

@implementation AtoZ (io)

__attribute__ ((constructor)) static void atozioInitialize(){

  printf("%s\n\n", "Welcome to AtoZ-io!");
  
}

+ (int) terminal_width { return self.terminalSize.width; }

+ (int) terminal_height { return self.terminalSize.height; }

+ (zTermSize) terminalSize {

    char * nterm = getenv("TERM");
    if (nterm) strcpy(term, nterm); 		/* We are running standalone, retrieve the terminal type from the environment. */
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    return (zTermSize){ w.ws_col, w.ws_row};
//    terminal_height = w.ws_row; 		/* Also get the number of columns */
//    printf("Window:%i x %i", terminal_width, terminal_height);
}

@end


#pragma mark - AtoZ Additions

void newline(int n) {

  for (int i = 0; i < n; ++i) { //	Telnet requires us to send a specific sequence for a line break (\r\000\n), so let's make it happy.
    if (!telnet) {
      putc('\n', stdout);  continue;  // Send a regular line feed
    }
    putc('\r', stdout);               // Send the telnet newline sequence
    putc(0,    stdout);                  // We will send `n` linefeeds to the client
    putc('\n', stdout);
  }
}


void print_with_newlines(char *first,...){

  int numlines = 0; char * line = first; va_list list; va_start(list, first);

  while (line != NULL) {               printf("%s",line);

    numlines = va_arg(list, int);     newline(numlines);
        line = va_arg(list, char*);
  }            va_end(list);
}

void reset_cursor() { printf("\033[%s", clear_screen ? "H" : "u"); }

