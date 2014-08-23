
#import "nyancat.h"

//		These values crop the animation, as we have a full 64x64 stored, but we only want to display 40x24 (double width).	
int min_row = 20, max_row = 43, min_col = 10, max_col = 50;
static char term[1024] = {'a', 'n', 's', 'i', 0}; //	 The default terminal is ANSI 

@implementation  NyanCat  {
  dispatch_source_t sigUser;
  int terminal_width, k, ttype;
  uint32_t option, done, sb_mode, do_echo;
  char sb[1024]; //	 Various pieces for the telnet communication 
  short sb_len;
  char show_intro, skip_intro; //	 Whether or not to show the MOTD intro 
  //		These are the options we want to use as a telnet server. These are set in set_options()	
  unsigned char telnet_options[256], telnet_willack[256];
  //		These are the values we have set or agreed to during our handshake.  These are set in send_command(...)	
  unsigned char telnet_do_set[256], telnet_will_set[256];
}
+ (instancetype) nyanCat  { static id nyanCat = nil; static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{ nyanCat = self.new; }); return nyanCat;
}
- (int) ttype {


  // if(terminal_width > 80) terminal_width = 80; 	/* We don't want terminals
  // wider than 80 columns */
  /* Do our terminal detection */
  return [_term.lowercaseString isEqualToString:@"xterm"] || [_term.lowercaseString isEqualToString:@"toaru"] ? 1 :
   /* 256-color, spaces */ /* emulates xterm */
  [_term.lowercaseString isEqualToString:@"linux"] ? 3 : /* Spaces and blink attribute */
  [_term.lowercaseString isEqualToString:@"vtnt"] || /* Extended ASCII fallback == Windows */ [_term.lowercaseString isEqualToString:@"cygwin"] ? 5 : /* Extended ASCII fallback == Windows */
  [_term.lowercaseString isEqualToString:@"vt220"] ? 6 : /* No color support */
  [_term.lowercaseString isEqualToString:@"fallback"] ? 4 : /* Unicode fallback */
  [_term.lowercaseString isEqualToString:@"rxvt"] ? 3 : /* Accepts LINUX mode */
  [_term.lowercaseString isEqualToString:@"vt100"] && terminal_width == 40 ? 7 : /* No color support, only 40 columns */
  ![_term.lowercaseString isEqualToString:@"st"] ? 2 : 1; /* suckless simple terminal is xterm-256color-compatible */
                                                      /* Everything else */
}

- (void) set_options {
  telnet_options[ECHO] = WONT;  // We will not echo input
  telnet_options[SGA] = WILL;  // We will set graphics modes
  telnet_options[NEW_ENVIRON] = WONT;  // We will not set new environments
  telnet_willack[ECHO] = DO;  // The client should echo its own input
  telnet_willack[SGA] = DO;  // The client can set a graphics mode
  telnet_willack[NAWS] = DO;  // The client should not change, but it should
  // tell us its window size
  telnet_willack[TTYPE] = DO;  // The client should tell us its terminal type (very important)
  telnet_willack[LINEMODE] = DONT;  // No linemode
  telnet_willack[NEW_ENVIRON] = DO;  // And the client can set a new environment
} //		Set the default options for the telnet server.	
- (void) send_command:(int) cmd opt:(int)opt {
  if (cmd == DO || cmd == DONT) {//	 Send a command to the telnet client 
    //	 DO commands say what the client should do. 
    if (((cmd == DO) && (telnet_do_set[opt] != DO)) ||
        ((cmd == DONT) && (telnet_do_set[opt] != DONT))) {
      telnet_do_set[opt] =
      cmd; //	 And we only send them if there is a disagreement 
      printf("%c%c%c", IAC, cmd, opt);
    }
  } else if (cmd == WILL || cmd == WONT) {
    //	 Similarly, WILL commands say what the server will do. 
    if (((cmd == WILL) && (telnet_will_set[opt] != WILL)) ||
        ((cmd == WONT) && (telnet_will_set[opt] != WONT))) {
      telnet_will_set[opt] =
      cmd; //	 And we only send them during disagreements 
      printf("%c%c%c", IAC, cmd, opt);
    }
  } else
    printf("%c%c", IAC, cmd); //	 Other commands are sent raw 
} //		Send a command (cmd) to the telnet client Also does special handling for DO/DONT/WILL/WONT	
- (void) finish {
  _clear_screen ? printf("\033[?25h\033[0m\033[H\033[2J") : printf("\033[0m\n");
  exit(0);
} //		Print escape sequences to return cursor to visible mode and exit the application.	
- (void) newline:(int)n {

  for (int i = 0; i < n; ++i) //	 We will send `n` linefeeds to the client 
    if (_inTelnet) {
      putc('\r', stdout); //	 Send the telnet newline sequence 
      putc(0, stdout);
      putc('\n', stdout);
    } else
      putc('\n', stdout); //	 Send a regular line feed 
} //		Telnet requires us to send a specific sequence for a line break (\r\000\n), so let's make it happy.	

- (void) play {

  //	 Store the start time 
  time_t start, current;
  time(&start);

  int playing = 1; //	 Animation should continue [left here for modifications] 
  size_t i = 0; //	 Current frame # 
  unsigned int f = 0; //	 Total frames passed 
  char last = 0; //	 Last color index rendered 
  size_t y, x; //	 x/y coordinates of what we're drawing 
  while (playing) {
    //	 Reset cursor 
    _clear_screen ? printf("\033[H") : printf("\033[u");
    //	 Render the frame 
    for (y = min_row; y < max_row; ++y) {
      for (x = min_col; x < max_col; ++x) {
//        if (always_escape)
//          printf("%s", colors[frames[i][y][x]]); /* Text mode (or "Always Send Color Escapes") */
//        else {
          if (frames[i][y][x] != last && colors[frames[i][y][x]]) {
            //	 Normal Mode, send escape (because the color changed) 
              last = frames[i][y][x];
            printf("%s%s", colors[frames[i][y][x]], output);
          } else printf("%s", output); //	 Same color, just send the output characters
//        }
      }
      [self newline:1]; //	 End of row, send newline
    }
/**
    if (show_counter) {
      time(&current);  // Get the current time for the "You have nyaned..."
      // string
      double diff = difftime(current, start);
      int nLen = digits((int)diff);  // Now count the length of the time
      // difference so we can center
      int anim_width = terminal_width == 80 ? (max_col - min_col) * 2 : (max_col - min_col);
      // 	29 = the length of the rest of the string; XXX: Replace this was actually checking the written bytes from a call to sprintf or something
      int width = (anim_width - 29 - nLen) / 2;
      while (width > 0)
        printf(" "),
        width--; //	 Spit out some spaces so that we're actually centered 

      // 	The \033[J ensures that the rest of the line has the dark blue  background, and the \033[1;37m ensures
      //  that our text is bright white. The \033[0m prevents the Apple ][ from flipping everything,  but makes the whole nyancat less bright on the vt220

        printf("\033[1;37mYou have nyaned for %0.0f seconds!\033[J\033[0m", diff);
    }
    */
    last = 0;  // Reset the last color so that the escape sequences rewrite
    ++f;  // Update frame count
    if (frame_count != 0 && f == frame_count)
      finish();
    ++i;
    if (!frames[i])  i = 0;  // Loop animation
    usleep(90000);  // Wait
  }
}
- (void) setInTelnet:(BOOL)inTelnet {   _inTelnet = inTelnet;

/*
  if (_inTelnet) {  // Telnet mode

    sigUser = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGALRM, 0, dispatch_get_global_queue(0, 0));
    //Next, we set its event handler with a block to execute, and then resume the source to make it active:
    dispatch_source_set_event_handler(sigUser, ^{
      printf("got SIGUSR1\n");\
    });
    dispatch_resume(sigUser);
    //  Like with kqueue, this exists separately from sigaction, so we have to tell sigaction to ignore the signal:
    struct sigaction action = { 0 };
    action.sa_handler = SIG_IGN;
    sigaction(SIGUSR1, &action, NULL);

    show_intro = !skip_intro; // show_intro is implied unless skip_intro was set
    [self set_options]; // Set the default options
    for (option = 0; option < 256;
         option++) /* Let the client know what we're using
      if (telnet_options[option])
        [self send_command:telnet_options[option] opt:option], fflush(stdout);
    for (option = 0; option < 256; option++)
      if (telnet_willack[option])
        [self send_command:telnet_willack[option] opt:option], fflush(stdout);
    signal(SIGALRM,SIGALRM_handler(self)); // Set the alarm handler to execute the longjmp
    if (!setjmp(environment)) { // Negotiate options
      // We will stop handling options after one second
      alarm(1);
      while (!feof(stdin) && done < 2) {// Let's do this
        // Get either IAC (start command) or a regular character (break, unless in SB mode)
        unsigned char i = getchar(), opt = 0;
        if (i == IAC) {
          i = getchar(); // If IAC, get the command 
          switch (i) {
            case SE:
              //	 End of extended option mode 
              sb_mode = 0;
              if (sb[0] == TTYPE) {
                // This was a response to the TTYPE command, meaning that this should be a terminal type
                alarm(2);
                strcpy(term, &sb[2]);
                done++;
              } else if (sb[0] == NAWS) {
                // This was a response to the NAWS command, meaning that this should be a window size
                alarm(2);
                terminal_width = sb[2];
                done++;
              }
              break;
            case NOP:
              //	 No Op 
              send_command(NOP, 0);
              fflush(stdout);
              break;
            case WILL:
            case WONT:
              //	 Will / Won't Negotiation 
              opt = getchar();
              if (!telnet_willack[opt]) {
                //	 We default to WONT 
                telnet_willack[opt] = WONT;
              }
              send_command(telnet_willack[opt], opt);
              fflush(stdout);
              if ((i == WILL) && (opt == TTYPE)) {
                //	 WILL TTYPE? Great, let's do that now! 
                printf("%c%c%c%c%c%c", IAC, SB, TTYPE, SEND, IAC, SE);
                fflush(stdout);
              }
              break;
            case DO:
            case DONT:
              //	 Do / Don't Negotiation 
              opt = getchar();
              if (!telnet_options[opt]) {
                //	 We default to DONT 
                telnet_options[opt] = DONT;
              }
              send_command(telnet_options[opt], opt);
              if (opt == ECHO) {
                // We don't really need this, as we don't accept input, but, in case we do in the future, set our echo mode
                do_echo = (i == DO);
              }
              fflush(stdout);
              break;
            case SB:
              //	 Begin Extended Option Mode 
              sb_mode = 1;
              sb_len = 0;
              memset(sb, 0, sizeof(sb));
              break;
            case IAC:
              //	 IAC IAC? That's probably not right. 
              done = 2;
              break;
            default:
              break;
          }
        } else if (sb_mode && sb_len < sizeof(sb) - 1) {// Extended Option Mode -> Accept character
          // 	Append this character to the SB string, but only if it doesn't put us over our limit; honestly, we shouldn't hit the limit, as we're only collecting characters for a terminal type or window size, but better safe than sorry (and vulnerable).
          sb[sb_len] = i;
          sb_len++;
        }
      }
    }
    alarm(0);
  } else {
  */
    /* We are running standalone, retrieve the terminal type from the environment. */
    struct winsize w; //	 Also get the number of columns
    ioctl(0, TIOCGWINSZ, &w);
    terminal_width = w.ws_col;

}
- (id) initWithArgC:(int)argc argv:(char **)argv {   //int main(int argc, char **argv)

	if (self != super.init ) return nil;
  terminal_width = 80;
   _term = [NSString stringWithUTF8String:getenv("TERM")?:""];
  [self setInTelnet:NO];
  return self;
}
- (void) setOpts:(int)argc v:(char**)argv {

  static struct option long_opts[] = {//	 Long option names 
    {"help",        no_argument,        0, 'h'},
    {"telnet",      no_argument,        0, 't'},
    {"intro",       no_argument,        0, 'i'},
    {"skip-intro",  no_argument,        0, 'I'},
    {"no-counter",  no_argument,        0, 'n'},
    {"no-title",    no_argument,        0, 's'},
    {"no-clear",    no_argument,        0, 'e'},
    {"frames",      required_argument,  0, 'f'},
    {"min-rows",    required_argument,  0, 'r'},
    {"max-rows",    required_argument,  0, 'R'},
    {"min-cols",    required_argument,  0, 'c'},
    {"max-cols",    required_argument,  0, 'C'},
    {"width",       required_argument,  0, 'W'},
    {"height",       required_argument, 0, 'H'}, {0, 0, 0, 0}};
  //	 Process arguments 
  int index, c;
  while ((c = getopt_long(argc, argv, "eshiItnf:r:R:c:C:W:H:", long_opts, &index)) != -1) {
    if (!c && !long_opts[index].flag)
      c = long_opts[index].val;
    switch (c) {
      case 'e':
        _clear_screen = 0;
        break;
      case 's':
        _set_title = 0;
        break;
      case 'i':
        show_intro = 1;
        break; //	 Show introduction 
      case 'I':
        skip_intro = 1;
        break;
      case 't':
        [self setInTelnet:YES];
        break; //	 Expect telnet bits 
      case 'h':
        [self usage:argv];
        exit(0);
        break; //	 Show help and exit 
      case 'n':
        _show_counter = 0;
        break;
      case 'f':
        _frame_count = atoi(optarg);
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
}

- (char*) colors {

  char *colors[246];
  int always_escape = 0; //	 Used for text mode 
//  signal(SIGINT, SIGINT_handler); //	 Accept ^C -> restore cursor 
//  signal(SIGPIPE, SIGPIPE_handler); //	 Handle loss of stdout
  switch (ttype) {
    case 1:
      colors[','] = "\033[48;5;17m"; //	 Blue background 
      colors['.'] = "\033[48;5;231m"; //	 White stars 
      colors['\''] = "\033[48;5;16m"; //	 Black border 
      colors['@'] = "\033[48;5;230m"; //	 Tan poptart 
      colors['$'] = "\033[48;5;175m"; //	 Pink poptart 
      colors['-'] = "\033[48;5;162m"; //	 Red poptart 
      colors['>'] = "\033[48;5;196m"; //	 Red rainbow 
      colors['&'] = "\033[48;5;214m"; //	 Orange rainbow 
      colors['+'] = "\033[48;5;226m"; //	 Yellow Rainbow 
      colors['#'] = "\033[48;5;118m"; //	 Green rainbow 
      colors['='] = "\033[48;5;33m"; //	 Light blue rainbow 
      colors[';'] = "\033[48;5;19m"; //	 Dark blue rainbow 
      colors['*'] = "\033[48;5;240m"; //	 Gray cat face 
      colors['%'] = "\033[48;5;175m"; //	 Pink cheeks 
      break;
    case 2:
      colors[','] = "\033[104m"; //	 Blue background 
      colors['.'] = "\033[107m"; //	 White stars 
      colors['\''] = "\033[40m"; //	 Black border 
      colors['@'] = "\033[47m"; //	 Tan poptart 
      colors['$'] = "\033[105m"; //	 Pink poptart 
      colors['-'] = "\033[101m"; //	 Red poptart 
      colors['>'] = "\033[101m"; //	 Red rainbow 
      colors['&'] = "\033[43m"; //	 Orange rainbow 
      colors['+'] = "\033[103m"; //	 Yellow Rainbow 
      colors['#'] = "\033[102m"; //	 Green rainbow 
      colors['='] = "\033[104m"; //	 Light blue rainbow 
      colors[';'] = "\033[44m"; //	 Dark blue rainbow 
      colors['*'] = "\033[100m"; //	 Gray cat face 
      colors['%'] = "\033[105m"; //	 Pink cheeks 
      break;
    case 3:
      colors[','] = "\033[25;44m"; //	 Blue background 
      colors['.'] = "\033[5;47m"; //	 White stars 
      colors['\''] = "\033[25;40m"; //	 Black border 
      colors['@'] = "\033[5;47m"; //	 Tan poptart 
      colors['$'] = "\033[5;45m"; //	 Pink poptart 
      colors['-'] = "\033[5;41m"; //	 Red poptart 
      colors['>'] = "\033[5;41m"; //	 Red rainbow 
      colors['&'] = "\033[25;43m"; //	 Orange rainbow 
      colors['+'] = "\033[5;43m"; //	 Yellow Rainbow 
      colors['#'] = "\033[5;42m"; //	 Green rainbow 
      colors['='] = "\033[25;44m"; //	 Light blue rainbow 
      colors[';'] = "\033[5;44m"; //	 Dark blue rainbow 
      colors['*'] = "\033[5;40m"; //	 Gray cat face 
      colors['%'] = "\033[5;45m"; //	 Pink cheeks 
      break;
    case 4:
      colors[','] = "\033[0;34;44m"; //	 Blue background 
      colors['.'] = "\033[1;37;47m"; //	 White stars 
      colors['\''] = "\033[0;30;40m"; //	 Black border 
      colors['@'] = "\033[1;37;47m"; //	 Tan poptart 
      colors['$'] = "\033[1;35;45m"; //	 Pink poptart 
      colors['-'] = "\033[1;31;41m"; //	 Red poptart 
      colors['>'] = "\033[1;31;41m"; //	 Red rainbow 
      colors['&'] = "\033[0;33;43m"; //	 Orange rainbow 
      colors['+'] = "\033[1;33;43m"; //	 Yellow Rainbow 
      colors['#'] = "\033[1;32;42m"; //	 Green rainbow 
      colors['='] = "\033[1;34;44m"; //	 Light blue rainbow 
      colors[';'] = "\033[0;34;44m"; //	 Dark blue rainbow 
      colors['*'] = "\033[1;30;40m"; //	 Gray cat face 
      colors['%'] = "\033[1;35;45m"; //	 Pink cheeks 
      output = "██";
      break;
    case 5:
      colors[','] = "\033[0;34;44m"; //	 Blue background 
      colors['.'] = "\033[1;37;47m"; //	 White stars 
      colors['\''] = "\033[0;30;40m"; //	 Black border 
      colors['@'] = "\033[1;37;47m"; //	 Tan poptart 
      colors['$'] = "\033[1;35;45m"; //	 Pink poptart 
      colors['-'] = "\033[1;31;41m"; //	 Red poptart 
      colors['>'] = "\033[1;31;41m"; //	 Red rainbow 
      colors['&'] = "\033[0;33;43m"; //	 Orange rainbow 
      colors['+'] = "\033[1;33;43m"; //	 Yellow Rainbow 
      colors['#'] = "\033[1;32;42m"; //	 Green rainbow 
      colors['='] = "\033[1;34;44m"; //	 Light blue rainbow 
      colors[';'] = "\033[0;34;44m"; //	 Dark blue rainbow 
      colors['*'] = "\033[1;30;40m"; //	 Gray cat face 
      colors['%'] = "\033[1;35;45m"; //	 Pink cheeks 
      output = "\333\333";
      break;
    case 6:
      colors[','] = "::"; //	 Blue background 
      colors['.'] = "@@"; //	 White stars 
      colors['\''] = "  "; //	 Black border 
      colors['@'] = "##"; //	 Tan poptart 
      colors['$'] = "??"; //	 Pink poptart 
      colors['-'] = "<>"; //	 Red poptart 
      colors['>'] = "##"; //	 Red rainbow 
      colors['&'] = "=="; //	 Orange rainbow 
      colors['+'] = "--"; //	 Yellow Rainbow 
      colors['#'] = "++"; //	 Green rainbow 
      colors['='] = "~~"; //	 Light blue rainbow 
      colors[';'] = "$$"; //	 Dark blue rainbow 
      colors['*'] = ";;"; //	 Gray cat face 
      colors['%'] = "()"; //	 Pink cheeks 
      always_escape = 1;
      break;
    case 7:
      colors[','] = "."; //	 Blue background 
      colors['.'] = "@"; //	 White stars 
      colors['\''] = " "; //	 Black border 
      colors['@'] = "#"; //	 Tan poptart 
      colors['$'] = "?"; //	 Pink poptart 
      colors['-'] = "O"; //	 Red poptart 
      colors['>'] = "#"; //	 Red rainbow 
      colors['&'] = "="; //	 Orange rainbow 
      colors['+'] = "-"; //	 Yellow Rainbow 
      colors['#'] = "+"; //	 Green rainbow 
      colors['='] = "~"; //	 Light blue rainbow 
      colors[';'] = "$"; //	 Dark blue rainbow 
      colors['*'] = ";"; //	 Gray cat face 
      colors['%'] = "o"; //	 Pink cheeks 
      always_escape = 1;
      terminal_width = 40;
      break;
    default:
      break;
  }
  return @{};
}

//		Print the usage / help text describing options	
- (void) usage:(char *[])argv {
  printf(
         "Terminal Nyancat\n"
         "\n"
         "usage: %s [-hitn] [-f \033[3mframes\033[0m]\n"
         "\n"
         " -i --intro      \033[3mShow the introduction / about information at "
         "startup.\033[0m\n"
         " -t --telnet     \033[3mTelnet mode.\033[0m\n"
         " -n --no-counter \033[3mDo not display the timer\033[0m\n"
         " -s --no-title   \033[3mDo not set the titlebar text\033[0m\n"
         " -e --no-clear   \033[3mDo not clear the display between frames\033[0m\n"
         " -f --frames     \033[3mDisplay the requested number of frames, then "
         "quit\033[0m\n"
         " -r --min-rows   \033[3mCrop the animation from the top\033[0m\n"
         " -R --max-rows   \033[3mCrop the animation from the bottom\033[0m\n"
         " -c --min-cols   \033[3mCrop the animation from the left\033[0m\n"
         " -C --max-cols   \033[3mCrop the animation from the right\033[0m\n"
         " -W --width      \033[3mCrop the animation to the given width\033[0m\n"
         " -H --height     \033[3mCrop the animation to the given height\033[0m\n"
         " -h --help       \033[3mShow this help message.\033[0m\n",
         argv[0]);
}
@end
//		Handle the alarm which breaks us off of options handling if we didn't receive a terminal	
//void SIGALRM_handler(int i) { alarm(0);  longjmp(environment, 1); /* Unreachable */ }
//		In the standalone mode, we want to handle an interrupt signal (^C) so that we can restore the cursor and clear the terminal.	
//- (void) SIGINT_handler:(int)sig {  [self finish]; }
//		Handle the loss of stdout, as would be the case when in telnet mode and the client disconnects	
//- (void) SIGPIPE_handler:(int)sig {   [self finish];  }

/*
 if (set_title) {// Attempt to set terminal title
 printf("\033kNyanyanyanyanyanyanya...\033\134");
 printf("\033]1;Nyanyanyanyanyanyanya...\007");
 printf("\033]2;Nyanyanyanyanyanyanya...\007");
 }
 clear_screen ? printf("\033[H\033[2J\033[?25l") : printf("\033[s"); // Clear the screen
 if (show_intro) {
 int countdown_clock = 5; // Display the MOTD
 for (k = 0; k < countdown_clock; ++k) {
 newline(3);
 printf(
 "                             \033[1mNyancat Telnet Server\033[0m");
 newline(2);
 printf(
 "                   written and run by \033[1;32mKevin "
 "Lange\033[1;34m @kevinlange\033[0m");
 newline(2);
 printf("        If things don't look right, try:");
 newline(1);
 printf("                TERM=fallback telnet ...");
 newline(2);
 printf("        Or on Windows:");
 newline(1);
 printf("                telnet -t vtnt ...");
 newline(2);
 printf("        Problems? Check the website:");
 newline(1);
 printf("                \033[1;34mhttp://nyancat.dakko.us\033[0m");
 newline(2);
 printf("        This is a telnet server, remember your escape keys!");
 newline(1);
 printf("                \033[1;31m^]quit\033[0m to exit");
 newline(2);
 printf("        Starting in %d...                \n",
 countdown_clock - k);

 fflush(stdout);
 usleep(4000000);
 clear_screen ? printf("\033[H") : printf("\033[u"); // Reset cursor
 }
 if (clear_screen)
 printf("\033[H\033[2J\033[?25l"); /// Clear the screen again
 }
 */
   //  option = 0;
  //  done = 0;
  //  sb_mode = 0;
  //  do_echo = 0;
  //  sb[1024] = {0}; //	 Various pieces for the telnet communication 
  //  sb_len = 0;
  //  show_intro = 0;
  //  skip_intro = 0; //	 Whether or not to show the MOTD intro 
