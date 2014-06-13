
#import <atozio.h>

//#import <AtoZ/AtoZ.h>
//#ifndef TIOCGWINSZ
//#include <termios.h>
//#endif
#ifdef ECHO
#undef ECHO
#endif

//void setup_telnet(); // predeclare

/*!	@discussion telnet.h contains some #defines for the various commands, escape characters, and modes for telnet.
                  (it surprises some people that telnet is, really, a protocol, and not just raw text transmission)
 */
#import "telnet.h"
#import "animation.h" //	The animation frames are stored separately in 	this header so they don't clutter the core source

/*	Count the number of digits in a number for	use with string output.	I refuse to include libm to keep this low on external dependencies. */
static int digits(int val) {	int d = 1, c;	if (val >= 0) for (c = 10; c <= val; c *= 10) d++; else for (c = -10 ; c >= val; c *= 10) d++; return (c < 0) ? ++d : d; }

/*	Print escape sequences to return cursor to visible mode	and exit the application.		*/
void finish(BOOL clrScrn) {	printf(clrScrn ? "\033[?25h\033[0m\033[H\033[2J":"\033[0m\n"); exit(0); }


char       * output = "  ";
char  * colors[256] = {NULL}; //	Color palette to use for final output Specifically, this should be either control sequences or raw characters (ie, for vt220 mode)
BOOL   show_counter = YES,    //	Whether or not to show the counter
          set_title = YES;    //	Force-set the terminal title.

jmp_buf environment;          //	Environment to use for setjmp/longjmp when breaking out of options handler

int     frame_count =  0,      //	Number of frames to show before quitting or 0 to repeat forever (default)
            min_row = -1,
            max_row = -1,
            min_col = -1,
            max_col = -1,     // These values crop the animation, as we have a full 64x64 stored, but we only want to display 40x24 (double width).
     terminal_width = 80,
    terminal_height = 24;     //	Actual width/height of terminal.

char using_automatic_width = 0, //	Flags to keep track of whether width/height were automatically set.
    using_automatic_height = 0;

void   SIGINT_handler(int sig) { finish(clear_screen); } // In the standalone mode, we want to handle an interrupt signal (^C) so that we can restore the cursor and clear the terminal.
void  SIGALRM_handler(int sig) { alarm(0); longjmp(environment, 1);	/* Unreachable */ } //	Handle the alarm which breaks us off of options	handling if we didn't receive a terminal
void  SIGPIPE_handler(int sig) { finish(clear_screen); } // Handle the loss of stdout, as would be the case when in telnet mode and the client disconnects
void SIGWINCH_handler(int sig) { struct winsize w;

  ioctl(0, TIOCGWINSZ, &w);                                terminal_width = w.ws_col;
                                                          terminal_height = w.ws_row;

  if (using_automatic_width)  { min_col = (FRAME_WIDTH  -  terminal_width  / 2)  / 2;
                                max_col = (FRAME_WIDTH  +  terminal_width  / 2)  / 2; }
  if (using_automatic_height) { min_row = (FRAME_HEIGHT - (terminal_height - 1)) / 2;
                                max_row = (FRAME_HEIGHT + (terminal_height - 1)) / 2; }
}


unsigned char telnet_options [256] = { 0 }, //	These are the options we want to use as a telnet server. These are set in set_options()
              telnet_willack [256] = { 0 },
               telnet_do_set [256] = { 0 }, // These are the values we have set or agreed to during our handshake. These are set in send_command(...)
             telnet_will_set [256] = { 0 };

void set_options() {  //  Set the default options for the telnet server.

  telnet_options        [ECHO] = WONT; // We will not echo input
  telnet_options         [SGA] = WILL; // We will set graphics modes
  telnet_options [NEW_ENVIRON] = WONT; // We will not set new environments
  telnet_willack        [ECHO] =   DO; // The client should echo its own input
  telnet_willack         [SGA] =   DO; // The client can set a graphics mode
  telnet_willack        [NAWS] =   DO; // The client should not change, but it should tell us its window size
  telnet_willack       [TTYPE] =   DO; // The client should tell us its terminal type (very important)
  telnet_willack    [LINEMODE] = DONT; // No linemode
  telnet_willack [NEW_ENVIRON] =   DO; // And the client can set a new environment
}

/*	Send a command (cmd) to the telnet client. Also does special handling for DO/DONT/WILL/WONT		*/
void send_command(int cmd, int opt) {
  if (cmd == DO || cmd == DONT) { 	/* Send a command to the telnet client */
    if (((cmd == DO) && (telnet_do_set[opt] != DO)) || 		/* DO commands say what the client should do. */
        ((cmd == DONT) && (telnet_do_set[opt] != DONT))) {
      telnet_do_set[opt] = cmd;				printf("%c%c%c", IAC, cmd, opt);		/* And we only send them if there is a disagreement */
    }
  } else if (cmd == WILL || cmd == WONT) {
    if (((cmd == WILL) && (telnet_will_set[opt] != WILL)) || 		/* Similarly, WILL commands say what the server will do. */
        ((cmd == WONT) && (telnet_will_set[opt] != WONT))) {
      telnet_will_set[opt] = cmd; 			/* And we only send them during disagreements */
      printf("%c%c%c", IAC, cmd, opt);
    }
  } else 		printf("%c%c", IAC, cmd);		/* Other commands are sent raw */
}

/*	Print the usage / help text describing options		*/
void usage(char * argv[]) {	printf(

                                   "Terminal Nyancat\
                                   usage: %s [-hitn] [-f \033[3mframes\033[0m]\
                                   \
                                   -i --intro      \033[3mShow the introduction / about information at startup.\033[0m\
                                   -t --telnet     \033[3mTelnet mode.\033[0m\n\
                                   -n --no-counter \033[3mDo not display the timer\033[0m\n\
                                   -s --no-title   \033[3mDo not set the titlebar text\033[0m\
                                   -e --no-clear   \033[3mDo not clear the display between frames\033[0m\
                                   -f --frames     \033[3mDisplay the requested number of frames, then quit\033[0m\
                                   -r --min-rows   \033[3mCrop the animation from the top\033[0m\
                                   -R --max-rows   \033[3mCrop the animation from the bottom\033[0m\
                                   -c --min-cols   \033[3mCrop the animation from the left\033[0m\
                                   -C --max-cols   \033[3mCrop the animation from the right\033[0m\
                                   -W --width      \033[3mCrop the animation to the given width\033[0m\
                                   -H --height     \033[3mCrop the animation to the given height\033[0m\
                                   -h --help       \033[3mShow this help message.\033[0m\n", argv[0]);
}



#pragma mark - MAIN

int main(int argc, char * argv[]) { @autoreleasepool {

  char term[1024] = {'a','n','s','i', 0};	int k, ttype, index, c;                           /* The default terminal is ANSI */

  uint32_t option = 0, done = 0, sb_mode = 0, __unused do_echo = 0;

  short sb_len = 0;	unsigned char sb[1024] = {0};                                           /* Various pieces for the telnet communication */

  char show_intro = 1, skip_intro = 0;                                                      /* Whether or not to show the MOTD intro */

  static struct option long_opts [] = {                                                      /* Long option names */

    {"help",       no_argument,       0, 'h'},  {"telnet",     no_argument,       0, 't'},
    {"intro",      no_argument,       0, 'i'},	{"skip-intro", no_argument,       0, 'I'},
    {"no-counter", no_argument,       0, 'n'},	{"no-title",   no_argument,       0, 's'},
    {"no-clear",   no_argument,       0, 'e'},	{"frames",     required_argument, 0, 'f'},
    {"min-rows",   required_argument, 0, 'r'},	{"max-rows",   required_argument, 0, 'R'},
    {"min-cols",   required_argument, 0, 'c'},	{"max-cols",   required_argument, 0, 'C'},
    {"width",      required_argument, 0, 'W'},	{"height",     required_argument, 0, 'H'},	{0,0,0,0}	};

  while ((c = getopt_long(argc,argv,"eshiItnf:r:R:c:C:W:H:",long_opts, &index)) != -1) {    /* Process arguments */
    c = c ?: !long_opts[index].flag ? long_opts[index].val : c;
    switch (c) {
      case 'e':
        clear_screen = 0;
        break;
      case 's':
        set_title = 0;
        break;
      case 'i': /* Show introduction */
        show_intro = 1;
        break;
      case 'I':
        skip_intro = 1;
        break;
      case 't': /* Expect telnet bits */
        telnet = 1;
        break;
      case 'h': /* Show help and exit */
        usage(argv);
        exit(0);
        break;
      case 'n':
        show_counter = 0;
        break;
      case 'f':
        frame_count = atoi(optarg);
        break;
      case 'r':
        min_row = atoi(optarg);
        break;
      case 'R':
        max_row = atoi(optarg);
        break;
      case 'c':
        min_col = atoi(optarg);
        break;
      case 'C':
        max_col = atoi(optarg);
        break;
      case 'W':
        min_col = (FRAME_WIDTH - atoi(optarg)) / 2;
        max_col = (FRAME_WIDTH + atoi(optarg)) / 2;
        break;
      case 'H':
        min_row = (FRAME_HEIGHT - atoi(optarg)) / 2;
        max_row = (FRAME_HEIGHT + atoi(optarg)) / 2;
        break;
      default:
        break;
    }
  }

  if (telnet) {     show_intro = (skip_intro == 0) ? 1 : 0;   		/* show_intro is implied unless skip_intro was set */
    set_options();  		/* Set the default options */
    for (option = 0; option < 256; option++) {          if (!telnet_options[option]) continue; 		/* Let the client know what we're using */
      send_command(telnet_options[option], option);	fflush(stdout);
    }
    for (option = 0; option < 256; option++) {          if (!telnet_willack[option]) continue;
      send_command(telnet_willack[option], option); fflush(stdout);
    }
    signal(SIGALRM, SIGALRM_handler); 		/* Set the alarm handler to execute the longjmp */
    if (!setjmp(environment)) {           		/* Negotiate options */
      alarm(1);                          			/* We will stop handling options after one second */
      while (!feof(stdin) && done < 2) {       			/* Let's do this */
        unsigned char i = getchar();          				/* Get either IAC (start command) or a regular character (break, unless in SB mode) */
        unsigned char opt = 0;
        if (i == IAC) {
          i = getchar();                   					/* If IAC, get the command */
          switch (i) {
            case SE:
              sb_mode = 0;                        							/* End of extended option mode */
              if (sb[0] == TTYPE) {
                alarm(2);               								/* This was a response to the TTYPE command, meaning that this should be a terminal type */
                strcpy(term, (const char*)&sb[2]);
                done++;
              }
              else if (sb[0] == NAWS) {
                /* This was a response to the NAWS command, meaning
                 * that this should be a window size */
                alarm(2);
                terminal_width = (sb[1] << 8) | sb[2];
                terminal_height = (sb[3] << 8) | sb[4];
                done++;
              }
              break;
            case NOP:
              /* No Op */
              send_command(NOP, 0);
              fflush(stdout);
              break;
            case WILL:
            case WONT:
              /* Will / Won't Negotiation */
              opt = getchar();
              if (!telnet_willack[opt]) {
                /* We default to WONT */
                telnet_willack[opt] = WONT;
              }
              send_command(telnet_willack[opt], opt);
              fflush(stdout);
              if ((i == WILL) && (opt == TTYPE)) {
                /* WILL TTYPE? Great, let's do that now! */
                printf("%c%c%c%c%c%c", IAC, SB, TTYPE, SEND, IAC, SE);
                fflush(stdout);
              }
              break;
            case DO:
            case DONT:
              /* Do / Don't Negotiation */
              opt = getchar();
              if (!telnet_options[opt]) {
                /* We default to DONT */
                telnet_options[opt] = DONT;
              }
              send_command(telnet_options[opt], opt);
              /* if (opt == ECHO) do_echo = (i == DO);	We don't really need this, as we don't accept input, but, in case we do in the future, set our echo mode */
              fflush(stdout);
              break;
            case SB:
              /* Begin Extended Option Mode */
              sb_mode = 1;
              sb_len  = 0;
              memset(sb, 0, sizeof(sb));
              break;
            case IAC:
              /* IAC IAC? That's probably not right. */
              done = 2;
              break;
            default:
              break;
          }
        } else if (sb_mode &&	sb_len < sizeof(sb) - 1) sb[sb_len] = i;	sb_len++;			/* Extended Option Mode -> Accept character */

        /*  Append this character to the SB string, but only if it doesn't put us over our limit;
         honestly, we shouldn't hit the limit, as we're only collecting characters for a
         terminal type or window size, but better safe than sorry (and vulnerable).        */
      }
    }
    alarm(0);
  } /* Telnet mode */
  else {

    char * nterm = getenv("TERM");

    if (nterm) strcpy(term, nterm); 		/* We are running standalone, retrieve the terminal type from the environment. */
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    terminal_width  = w.ws_col;
    terminal_height = w.ws_row; 		/* Also get the number of columns */
    printf("Window:%i x %i", terminal_width, terminal_height);
  }

  //	for (k = 0; k < strlen(term); ++k) term[k] = tolower(term[k]); 	/* Convert the entire terminal string to lower case */
  ttype = 1;
  int always_escape = 0;                            /* Used for text mode */
  signal(SIGINT,   SIGINT_handler);    /* Accept ^C -> restore cursor */
  signal(SIGPIPE,  SIGPIPE_handler);  	/* Handle loss of stdout */
  if (!telnet) signal(SIGWINCH, SIGWINCH_handler); 	/* Handle window changes */

  colors[',']  = "\033[48;5;17m";  /* Blue background */
  colors['.']  = "\033[48;5;231m"; /* White stars */
  colors['\''] = "\033[48;5;16m";  /* Black border */
  colors['@']  = "\033[48;5;230m"; /* Tan poptart */
  colors['$']  = "\033[48;5;175m"; /* Pink poptart */
  colors['-']  = "\033[48;5;162m"; /* Red poptart */
  colors['>']  = "\033[48;5;196m"; /* Red rainbow */
  colors['&']  = "\033[48;5;214m"; /* Orange rainbow */
  colors['+']  = "\033[48;5;226m"; /* Yellow Rainbow */
  colors['#']  = "\033[48;5;118m"; /* Green rainbow */
  colors['=']  = "\033[48;5;33m";  /* Light blue rainbow */
  colors[';']  = "\033[48;5;19m";  /* Dark blue rainbow */
  colors['*']  = "\033[48;5;240m"; /* Gray cat face */
  colors['%']  = "\033[48;5;175m"; /* Pink cheeks */

  if (min_col == max_col) {	using_automatic_width = 1;

    min_col = (FRAME_WIDTH - terminal_width/2) / 2;
    max_col = (FRAME_WIDTH + terminal_width/2) / 2;

  }
  if (min_row == max_row) { using_automatic_height = 1;

    min_row = (FRAME_HEIGHT - (terminal_height-1)) / 2;
    max_row = (FRAME_HEIGHT + (terminal_height-1)) / 2;

    }

  if (set_title) {                                      	/* Attempt to set terminal title */
    printf("\033kNyanyanyanyanyanyanya...\033\134");
    printf("\033]1;Nyanyanyanyanyanyanya...\007");
    printf("\033]2;Nyanyanyanyanyanyanya...\007");
  }

  printf(clear_screen?"\033[H\033[2J\033[?25l": "\033[s"); 		/* Clear the screen */

  if (show_intro) {           /* Display the MOTD */
    int countdown_clock = 5;

      for (k = 0; k < countdown_clock; ++k) {

      print_with_newlines(" ", 3,
                          "          \033[1mNyancat Telnet Server\033[0m", 2,
                          "        written and run by \033[1;32mKevin Lange\033[1;34m @kevinlange\033[0m",2,
                          "        If things don't look right, try:", 1,
                          "                TERM=fallback telnet ...",2,
                          "        Or on Windows:",1,
                          "                telnet -t vtnt ...",2,
                          "        Problems? Check the website:",1,
                          "                \033[1;34mhttp://nyancat.dakko.us\033[0m",2,
                          "        This is a telnet server, remember your escape keys!", 1,
                          "                \033[1;31m^]quit\033[0m to exit",2,
                          CHAR_FMT("        Starting in %d...                \n", countdown_clock-k), 2, NULL);
      fflush(stdout);
      usleep(400000);

      reset_cursor();

    } clear_screen  ? printf("\033[H\033[2J\033[?25l")
                    : (void)nil;
  }
  /* Store the start time */
  time_t start, current;
  time(&start);

  int       playing = 1;    /* Animation should continue [left here for modifications] */
  size_t          i = 0;       /* Current frame # */
  unsigned int    f = 0; /* Total frames passed */
  __block char last = 0;      /* Last color index rendered */
  //	int y, x;        /* x/y coordinates of what we're drawing */
  while (playing) {

    reset_cursor();                                     /* Reset cursor */

    for (int y = min_row; y < max_row; ++y) {           /* Render the frame */                                                          //    IterateGridWithBlock( $RNGTOMAX(min_row, max_row), $RNGTOMAX(min_col, max_col), ^(NSI y, NSI x) {
      for (int x = min_col; x < max_col; ++x) {
        char color = y > 23 && y < 43 && x < 0 ? ({     /* Generate the rainbow tail. This is done with a pretty simplistic square wave. */

          int     mod_x = ((-x + 2) % 16) / 8;
          mod_x =  isEven(i) ? 1 - mod_x : mod_x;             //if ((i / 2) % 2) mod_x  = 1 - mod_x;    //char *rainbow = ",,>>&&&+++###==;;;,,";	/* Our rainbow, with some padding. */	rainbow
          ",,>>&&&+++###==;;;,,"[mod_x + y - 23];

        }) : x < 0 || y < 0 || y >= FRAME_HEIGHT || x >= FRAME_WIDTH ? ',' : frames[i][y][x]; 					/* Fill all other areas with background */

        /* Otherwise, get the color from the animation frame. */

        if (always_escape) 	printf("%s", colors[color]);			/* Text mode (or "Always Send Color Escapes") */
        else {
          if (color != last && colors[color])		/* Normal Mode, send escape (because the color changed) */

            printf("%s%s", colors[last = color], output);
          else printf("%s", output);	/* Same color, just send the output characters */
        }

      }
      /* End of row, send newline */
      newline(1);
    }

    //	/* Store the start time */
    //	time_t start, current;	time(&start);
    //
    //	int playing       = 1, y, x;    /* Animation should continue [left here for modifications] */            /* x/y coordinates of what we're drawing */
    //	size_t i          = 0;       /* Current frame # */
    //	unsigned int f    = 0; /* Total frames passed */
    //	__block char last = 0;      /* Last color index rendered */
    //	while (playing) {
    //    printf(clear_screen?"\033[H":"\033[u");  /* Reset cursor */
    ////    IterateGridWithBlock($RNG(min_row,max_row - min_row),$RNG(min_col,max_col - min_col), ^(NSI x, NSI y) {
    //    for (y = min_row; y < max_row; ++y) {   		/* Render the frame */
    //      for (x = min_col; x < max_col; ++x) {
    //      char color =  y > 23 && y < 43 && x < 0 ? ({
    //        int mod_x = ((-x+2) % 16) / 8;                        					/* Generate the rainbow tail. This is done with a pretty simplistic square wave. */
    //        if ((i / 2) % 2) 	mod_x = 1 - mod_x;
    //        char *rainbow = ",,>>&&&+++###==;;;,,";       					/* Our rainbow, with some padding. */
    //        rainbow[mod_x + y-23];
    //      }) : x < 0 || y < 0 || y >= FRAME_HEIGHT || x >= FRAME_WIDTH  /* Fill all other areas with background */
    //      ? ',': frames[i][y][x];  /* Otherwise, get the color from the animation frame. */
    //
    //      if (always_escape) 					printf("%s", colors[color]);					/* Text mode (or "Always Send Color Escapes") */
    //      else {
    //        if (color != last && colors[color]) {
    //          /* Normal Mode, send escape (because the color changed) */
    //          last = color;
    //          printf("%s%s", colors[color], output);
    //        } else printf("%s", output);					/* Same color, just send the output characters */
    //      }
    //      /* End of row, send newline */
    //			newline(1);
    //      }
    //    }
    if (show_counter) {  time(&current);                // Get the current time for the "You have nyaned..." string
      
      double diff = difftime(current, start);
      int nLen    = digits((int)diff);                  // Now count the length of the time difference so we can center
      int width   = (terminal_width - 29 - nLen) / 2;   // 29 = the length of the rest of the string;  XXX: Replace this was actually checking the written bytes from a call to sprintf or something */
      
      while (width > 0) { printf(" ");	width--;  }     // Spit out some spaces so that we're actually centered
      
      /*  You have nyaned for [n] seconds! The \033[J ensures that the rest of the line has the dark blue background,
       and the \033[1;37m ensures that our text is bright white. The \033[0m prevents the Apple ][ from flipping everything, 
       but makes the whole nyancat less bright on the vt220  	 */
      
      printf("\033[1;37mYou have nyaned for %0.0f seconds!\033[J\033[0m", diff);
    }
    
    last = 0;                                           // Reset the last color so that the escape sequences rewrite
    ++f;                                                // Update frame count
    if (frame_count != 0 && f == frame_count) finish(clear_screen);
    ++i;
    i = (!frames[i]) ?: i;                              // Loop animation
    usleep(90000);                                      // Wait
  }
}
  return 0;
}

/*
void(^)(int,uint32_t) setup_telet(void) { return ^void(int show_intro, uint32_t option){


//    show_intro = (skip_intro == 0) ? 1 : 0;   		// show_intro is implied unless skip_intro was set */
//    set_options();  		/* Set the default options */
//    for (option = 0; option < 256; option++) {          if (!telnet_options[option]) continue; 		/* Let the client know what we're using */
//      send_command(telnet_options[option], option);	fflush(stdout);
//    }
//    for (option = 0; option < 256; option++) {          if (!telnet_willack[option]) continue;
//      send_command(telnet_willack[option], option); fflush(stdout);
//    }
//    signal(SIGALRM, SIGALRM_handler); 		/* Set the alarm handler to execute the longjmp */
//    if (!setjmp(environment)) {           		/* Negotiate options */
//      alarm(1);                          			/* We will stop handling options after one second */
//      while (!feof(stdin) && done < 2) {       			/* Let's do this */
//        unsigned char i = getchar();          				/* Get either IAC (start command) or a regular character (break, unless in SB mode) */
//        unsigned char opt = 0;
//        if (i == IAC) {
//          i = getchar();                   					/* If IAC, get the command */
//          switch (i) {
//            case SE:
//              sb_mode = 0;                        							/* End of extended option mode */
//              if (sb[0] == TTYPE) {
//                alarm(2);               								/* This was a response to the TTYPE command, meaning that this should be a terminal type */
//                strcpy(term, (const char*)&sb[2]);
//                done++;
//              }
//              else if (sb[0] == NAWS) {
//                /* This was a response to the NAWS command, meaning
//                 * that this should be a window size */
//                alarm(2);
//                terminal_width = (sb[1] << 8) | sb[2];
//                terminal_height = (sb[3] << 8) | sb[4];
//                done++;
//              }
//              break;
//            case NOP:
//              /* No Op */
//              send_command(NOP, 0);
//              fflush(stdout);
//              break;
//            case WILL:
//            case WONT:
//              /* Will / Won't Negotiation */
//              opt = getchar();
//              if (!telnet_willack[opt]) {
//                /* We default to WONT */
//                telnet_willack[opt] = WONT;
//              }
//              send_command(telnet_willack[opt], opt);
//              fflush(stdout);
//              if ((i == WILL) && (opt == TTYPE)) {
//                /* WILL TTYPE? Great, let's do that now! */
//                printf("%c%c%c%c%c%c", IAC, SB, TTYPE, SEND, IAC, SE);
//                fflush(stdout);
//              }
//              break;
//            case DO:
//            case DONT:
//              /* Do / Don't Negotiation */
//              opt = getchar();
//              if (!telnet_options[opt]) {
//                /* We default to DONT */
//                telnet_options[opt] = DONT;
//              }
//              send_command(telnet_options[opt], opt);
//              /* if (opt == ECHO) do_echo = (i == DO);	We don't really need this, as we don't accept input, but, in case we do in the future, set our echo mode */
//              fflush(stdout);
//              break;
//            case SB:
//              /* Begin Extended Option Mode */
//              sb_mode = 1;
//              sb_len  = 0;
//              memset(sb, 0, sizeof(sb));
//              break;
//            case IAC:
//              /* IAC IAC? That's probably not right. */
//              done = 2;
//              break;
//            default:
//              break;
//          }
//        } else if (sb_mode &&	sb_len < sizeof(sb) - 1) sb[sb_len] = i;	sb_len++;			/* Extended Option Mode -> Accept character */
//
//        /*  Append this character to the SB string, but only if it doesn't put us over our limit;
//         honestly, we shouldn't hit the limit, as we're only collecting characters for a
//         terminal type or window size, but better safe than sorry (and vulnerable).        */
//      }
//    }
//    alarm(0);
//  };
//}

//#include <ctype.h>
//#include <stdio.h>
//#include <stdint.h>
//#include <string.h>
//#include <stdlib.h>
//#include <unistd.h>
//#include <signal.h>
//#include <time.h>
//#include <setjmp.h>
//#include <getopt.h>
//#include <sys/ioctl.h>
//      newline(3);
//      printf("                             \033[1mNyancat Telnet Server\033[0m");
//      newline(2);
//      printf("                   written and run by \033[1;32mKevin Lange\033[1;34m @kevinlange\033[0m");
//      newline(2);
//      printf("        If things don't look right, try:");
//      newline(1);
//      printf("                TERM=fallback telnet ...");
//      newline(2);
//      printf("        Or on Windows:");
//      newline(1);
//      printf("                telnet -t vtnt ...");
//      newline(2);
//      printf("        Problems? Check the website:");
//      newline(1);
//      printf("                \033[1;34mhttp://nyancat.dakko.us\033[0m");
//      newline(2);
//      printf("        This is a telnet server, remember your escape keys!");
//      newline(1);
//      printf("                \033[1;31m^]quit\033[0m to exit");
//      newline(2);
