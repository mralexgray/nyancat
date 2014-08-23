
#import "atozio.h"
#import "DDEmbeddedDataReader.h"
#import <AQOptionParser.h>

#define GOT_TO printf("got to %i\n", __LINE__)

@implementation AtoZ (io)

+ (NSData*)embeddedDataFromSegment:(NSS*)seg inSection:(NSS*)sec error:(NSERR**)e {
  return [DDEmbeddedDataReader embeddedDataFromSegment:seg inSection:sec error:e];
}
+ (int) terminal_width      { return self.terminalSize.width; }
+ (int) terminal_height     { return self.terminalSize.height; }

+ (zTermSize) terminalSize  { char * nterm; struct winsize w;

  return (nterm = getenv("TERM")) ? strcpy(term, nterm), ioctl(0, TIOCGWINSZ, &w), (zTermSize){ w.ws_col, w.ws_row} :   (zTermSize){ -1,-1};
  /* We are running standalone, retrieve the terminal type from the environment. */
}
+ (AVAudioPlayer*) playerForAudio:(id)dataOrPath { //lets create an audio player to play the audio.

  NSERR *e; AVAudioPlayer *player =          [dataOrPath isKindOfClass:  NSData.class]
                                           ? [AVAudioPlayer.alloc initWithData:dataOrPath error:&e]
                                           : [dataOrPath isKindOfClass:   NSURL.class]
                                          || [dataOrPath isKindOfClass:NSString.class]
                                           ? [AVAudioPlayer.alloc initWithContentsOfURL:
                                             [dataOrPath isKindOfClass:NSURL.class]
                                           ?  dataOrPath
                                           : [NSURL fileURLWithPath:dataOrPath] error:&e]
                                           : nil;

  return !player || e ? NSLog(@"problem making player: %@", e), (id)nil
                      : [player setNumberOfLoops:-1], [player prepareToPlay], player; //prepare the file to play
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




int    CUBE_STEPS[] = { 0x00, 0x5F, 0x87, 0xAF, 0xD7, 0xFF };

RgbColor BASIC16[] = {  {   0,   0,   0 }, { 205,   0,   0}, {   0, 205,   0 }, { 205, 205,   0 }, {   0,   0, 238}, { 205,   0, 205 },
                        {   0, 205, 205 }, { 229, 229, 229}, { 127, 127, 127 }, { 255,   0,   0 }, {   0, 255,   0}, { 255, 255,   0 },
                        {  92,  92, 255 }, { 255,   0, 255}, {   0, 255, 255 }, { 255, 255, 255 } };

RgbColor  COLOR_TABLE[256];

RgbColor  xterm_to_rgb(int x)  { int calc; return

              x <   16 ? BASIC16[x] :
  232 <= x && x <= 255 ? (calc = 8 + (x - 232) * 0x0A), (RgbColor){ calc,calc,calc} :
   16 <= x && x <= 231 ? (  x -= 16),                   (RgbColor){ CUBE_STEPS[(x / 36) % 6], CUBE_STEPS[(x / 6) % 6], CUBE_STEPS[x % 6]}
                       :                                (RgbColor){ 0,0,0 };
}

#define sqr(x) ((x) * (x))

int rgb_to_xterm(int r, int g, int b) { return ({ /** Quantize RGB values to an xterm 256-color ID */

  int best_match = 0, smallest_distance = 1000000000, c, d;

  for (c = 16; c < 256; c++) { d = sqr(COLOR_TABLE[c].rVal - r) + sqr(COLOR_TABLE[c].gVal - g) + sqr(COLOR_TABLE[c].bVal - b);

    if (d < smallest_distance) { smallest_distance = d; best_match = c; } }  best_match; });
}

@implementation NSColor (atozio) @dynamic bg, fg;

+ (NSA*)    x16           { return [@16 mapTimes:^id(NSN* c){ return [self xColor:c.intValue]; }]; }
+ (NSC*) xColor:(int)x    { RgbColor z = xterm_to_rgb(x); return [self colorWithDeviceRed:z.r green:z.g blue:z.b alpha:1]; }
- (NSN*)   x256           { NSC*x = self.inRGB; return @(rgb_to_xterm(x.redComponent*255, x.greenComponent*255,x.blueComponent*255)); }
- (NSC*)     bg           { return !!self.otherColor &&  self.otherColor.isBGColor ? self.otherColor : nil;   }
- (NSC*)     fg           { return !!self.otherColor && !self.otherColor.isBGColor ? self.otherColor : self;  }
- (void)  setBg:(NSC*)b   { [self setOther:b isBG:YES]; }
- (void)  setFg:(NSC*)f   { [self setOther:f isBG:NO];  }
- (NSC*) withFG:(NSC*)c   { self.fg = c; return self; }
- (NSC*) withBG:(NSC*)c   { self.bg = c; return self; }
- (BOOL) isBGColor        { return !!objc_getAssociatedObject(self, _cmd); }
- (NSC*) otherColor       { return objc_getAssociatedObject(self, _cmd); }
- (void) setOther:(NSC*)c
             isBG:(BOOL)x { objc_setAssociatedObject(c,     @selector(isBGColor), x ? @YES : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                            objc_setAssociatedObject(self,  @selector(otherColor),             c, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

JREnumDefine(FMTOptions);

#pragma mark - COLOR

#define FMT_ESC "\x1b["
#define FMT_FG "38;05;"
#define FMT_BG "48;05;"

#define FMT_RESET     "0m"  // Reset all SGR options.
#define FMT_RESET_FG  "39m" // Reset foreground color.
#define FMT_RESET_BG  "49m" // Reset background color.

@implementation NSString (atozio)           SYNTHESIZE_ASC_OBJ (   color, setColor                );
                                  SYNTHESIZE_ASC_PRIMITIVE_KVO ( options, setOptions, FMTOptions  );

- (NSS*) fg       { return !self.color.fg ? @"" : $(@"38;05;%@;", self.color.fg.x256.strV); }
- (NSS*) bg       { return !self.color.bg ? @"" : $(@"48;05;%@;", self.color.bg.x256.strV); }
- (CCHAR) xString  { return !self.color ? self.UTF8String : $(@"" FMT_ESC "%@%@m%@" FMT_ESC FMT_RESET, self.fg, self.bg, self).UTF8String; }

+ (NSS*) withColor:(NSC*)c
               fmt:(NSS*)f
              args:(va_list)l    { NSS*x = [self stringWithFormat:f arguments:l]; return x ? x.color = c, x : nil; }
+ (NSS*) withColor:(NSC*)c
               fmt:(NSS*)fmt,... {

  va_list list; va_start(list,fmt); NSS *new = [self withColor:c fmt:fmt args:list]; va_end(list); return new;
}

- (void) xPrint { printf("%s\n", self.xString); }
@end

void    PrintInClr (const char*s, int c)    { printf("%s\n", [NSS withColor:[NSC xColor:c] fmt:@"%s",s].UTF8String);  }
void      PrintClr (int c)                  { PrintInClr("  ", c); }
void       ClrPlus (const char* c)          { printf("%s0m%s", FMT_ESC, c); }
void    FillScreen (int c)                  { [@(AtoZ.terminal_height) do:^(int ctr){ PrintInClr([@" " times:AtoZ.terminal_width].cchar, c); }]; }
void      Spectrum (void)                   {
 
  for(int r = 0; r < 6; r++) {
      for(int g = 0; g < 6; g++) {
          for(int b = 0; b < 6; b++) PrintClr( 16 + (r * 36) + (g * 6) + b );  ClrPlus("  ");
    }
    printf("\n");
  }
}
void     AllColors (void(^block)(int c))    { [@(255).toArray do:^(NSN*n){  block(n.intValue); }]; }
void   _PrintInRnd (id x, va_list list)     {

PrintInClr([NSS stringWithFormat:x arguments:list].UTF8String, arc4random_uniform(256)); }
void  PrintInRnd (id x,...)               { va_list list; va_start(list,x); _PrintInRnd(x, list); va_end(list);

}

__attribute__ ((constructor)) static void setupColors (){ for (int c = 0; c < 256; c++) COLOR_TABLE[c] = xterm_to_rgb(c); }




//void SystemGrays () { for (zColor color = 232; color < 256; color++)  PrintClr(color); }

//#define FG(X) "38;05;"#X
//
//#define FMT_BOLD      "1m"
//#define FMT_BOLD_OFF  "22m"
//#define FMT_UNDL      "4m"
//#define FMT_UNDL_OFF  "24m"
//#define FMT_BLNK      "5m" // Less then 150 per minute.
//#define FMT_BLNK_OFF  "25m"
//
//#define FMT_NEG       "7m"  // Set reversed-video active (foreground and background negative).
//#define FMT_POS       "27m" // Reset reversed-video to normal.
//
//#define FMT_FRAME     "51m"
//#define FMT_ENCIRCLE  "52m"
//#define FMT_ENCIRCLE_OFF "54m"
//
//#define FMT_OVERLINED     "53m"
//#define FMT_OVERLINED_OFF "55m"
//
//#define CLR_SCRN "\e[H\e[J"
