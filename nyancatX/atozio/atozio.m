
#import "atozio.h"
@import Darwin;
#import <getopt.h>
#import "DDEmbeddedDataReader.h"

#define GOT_TO printf("got to %i\n", __LINE__)

@implementation AtoZ (io)

__attribute__ ((constructor)) static void atozioInitialize(){

  printf("%s\n\n", "Welcome to AtoZ-io!");
  
}

+ (NSData*)embeddedDataFromSegment:(NSS*)seg inSection:(NSS*)sec error:(NSERR**)e {
  return [DDEmbeddedDataReader embeddedDataFromSegment:seg inSection:sec error:e];
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
+ (AVAudioPlayer*) playerForAudio:(id)dataOrPath {

  NSERR *e;
  AVAudioPlayer *player =
  [dataOrPath isKindOfClass:NSData.class] ? [AVAudioPlayer.alloc initWithData:dataOrPath error:&e] :
  [dataOrPath isKindOfClass:NSURL.class] || [dataOrPath isKindOfClass:NSString.class] ?
  [AVAudioPlayer.alloc initWithContentsOfURL:[dataOrPath isKindOfClass:NSURL.class] ? dataOrPath  : [NSURL fileURLWithPath:dataOrPath] error:&e] : nil; //lets create an audio player to play the audio.
  if (!player || e) return NSLog(@"problem making player: %@", e), (id)nil;
  player.numberOfLoops = -1; // -1 means infinite loops
  [player prepareToPlay]; //prepare the file to play
  return player;
}

+ (NSD*)parseArgs:(char *[])argv andKeys:(NSArray*)keys count:(int)argc {


//- (id)initWithArgs:(const char *[])argv andKeys:(NSArray *)keys count:(int)argc 
//{
//    self = [super init];
//    const char    ** _argv = argv;
//    int              _argc = argc;
//    NSArray        * _keys = keys;
    NSDictionary    * val_ = @{};

    if (argc == 1) return val_;

    int c; int o = (int)keys.count + 1; NSMS *fmt = NSMS.new;  struct option long_options[o];

    memset(&long_options, 0, sizeof(struct option)*o);

    for (int i = 0; i < keys.count; i++) {

        NSD *kv       = keys[i];
        NSS *name     = [kv objectForKey:@"name"];
        CCHAR n       = name.UTF8String;
        NSN *has_arg  = [kv objectForKey:@"has_arg"];
        int h_a;
        NSS *fl       = [kv objectForKey:@"flag"];
        unichar flag  = [fl characterAtIndex:0];
        if (has_arg.bV) {
            h_a = required_argument;
            [fmt appendFormat:@"%@:", fl];
        } else if (!has_arg.bV) {
            h_a = no_argument;
            [fmt appendString:fl];
        } else {
            h_a = optional_argument;
            [fmt appendFormat:@"%@::", fl];
        }
        long_options[i].name    = n;
        long_options[i].has_arg = h_a;
        long_options[i].flag    = NULL;
        long_options[i].val     = flag;
    }
    int last = o - 1;
    long_options[last].name = 0;
    long_options[last].has_arg = 0;
    long_options[last].flag = 0;
    long_options[last].val = 0;
    NSMutableDictionary *d = @{}.mC;
    int option_index = 0;

//    while ((c = getopt_long(argc,argv,"eshiItnf:r:R:c:C:W:H:",long_opts, &index)) != -1) {    /* Process arguments */
//    c = c ?: !long_opts[index].flag ? long_opts[index].val : c;
  while ((c = getopt_long(argc,argv,"eshiItnf:r:R:c:C:W:H:",long_options, &option_index)) != -1) {    /* Process arguments */

    c = c ?: !long_options[option_index].flag ? long_options[option_index].val : c;

//    while (YES) {
//      XX(argc); XX(argv); XX(fmt.UTF8String); XX( &option_index);
//GOT_TO;
//      c = getopt_long(argc, argv, fmt.UTF8String, long_options, &option_index);
//      XX(c);
//GOT_TO;
//        if (c == -1) break;
//        else {
//            NSS * k = [NSS stringWithCString:long_options[option_index].name encoding:NSUTF8StringEncoding];
//            id    v = optarg ? [NSS stringWithCString:optarg encoding:NSUTF8StringEncoding] : @YES;
//            [d setObject:v forKey:k];
//        }
GOT_TO;
    }
GOT_TO;
    int _i = -1;
    for (int i = 1; i < argc; i++) {
        NSS *arg = [NSS stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
        if ([arg rangeOfString:@"--"].location == NSNotFound) {  _i = i; /* First non-option argument. */ break; }
    }
GOT_TO;
    if (_i == -1) [d setObject:@NO forKey:@"{query}"];
    else {
        NSMS *q = @"".mC;
        for (int j = _i; j < argc; j++) [q appendFormat:@"%@ ", [NSString stringWithCString:argv[j] encoding:NSUTF8StringEncoding]];

        q = [NSMS stringWithString:[q stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
        [d setObject:q forKey:@"{query}"];
    }
    return [d copy];
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

void   clr_screen() { printf(clear_screen ? "\033[H\033[2J\033[?25l" : "\033[s"); 		/* Clear the screen */ }

