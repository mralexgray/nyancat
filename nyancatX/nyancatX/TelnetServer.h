
#include <sys/socket.h> /* for socket() and socket functions*/
#include <arpa/inet.h> /* for sockaddr_in and inet_ntoa() */

#define RCVBUFSIZE 32 /* Size of receive buffer */
#define MAXPENDING 5 /* Maximum outstanding connection requests */

@interface TelnetServer : NSObject

@property (readonly) NSUInteger port;

- (id) initOnPort:(NSInteger)port;

- (void) dieWithError:(char*)errorMessage; /* Error handling function */
- (void) handleTCPClient:(int)clntSocket; /* TCP client handling function */

@end
