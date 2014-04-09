
#import "TelnetServer.h"

@implementation TelnetServer{

  int servSock, /* Socket descriptor for server */
      clntSock; /* Socket descriptor for client */
  struct sockaddr_in echoServAddr; /* Local address */
  struct sockaddr_in echoClntAddr; /* Client address */
  unsigned int clntLen; /* Length of client address data structure */
}

- (id) initOnPort:(NSInteger)port { /* Server port */

	if (self != super.init ) return nil;
  _port = port;
  // if ( argc != 2 ) /* Test for correct number of arguments */
  // fprintf( stderr, "Usage:  %s <Server Port>\n", argv[0] ), exit( 1 );
  // echoServPort = atoi( argv[1] ); /* First arg:  local port */
  /* Create socket for incoming connections */
  if ((servSock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
    [self dieWithError:"socket() failed"];
  /* Construct local address structure */
  memset(&echoServAddr, 0, sizeof(echoServAddr)); /* Zero out structure */
  echoServAddr.sin_family = AF_INET; /* Internet address family */
  echoServAddr.sin_addr.s_addr = htonl(INADDR_ANY); /* Any incoming interface */
  echoServAddr.sin_port = htons(_port); /* Local port */
  /* Bind to the local address */
  if (bind(servSock, (struct sockaddr *)&echoServAddr, sizeof(echoServAddr)) < 0)
    [self dieWithError:"bind() failed"];
  /* Mark the socket so it will listen for incoming connections */
  if (listen(servSock, MAXPENDING) < 0)
    [self dieWithError:"listen() failed"];

  return self;
}
- (void) run {

  for (;;) { /* Run forever */
  clntLen = sizeof(echoClntAddr); /* Set the size of the in-out parameter */
  if ((clntSock = accept(servSock, (struct sockaddr *)&echoClntAddr, &clntLen)) < 0)         /* Wait for a client to connect */
    [self dieWithError:"accept() failed"];
    /* clntSock is connected to a client! */
        printf("Talking with client %s\n", inet_ntoa(echoClntAddr.sin_addr));
        [self handleTCPClient:clntSock];
    }
    /* NOT REACHED */
}
- (void) handleTCPClient:(int)clntSocket; /* TCP client handling function */
{
  char echoBuffer[RCVBUFSIZE]; /* Buffer for echo string */
  long recvMsgSize; /* Size of received message */
  if ((recvMsgSize = recv(clntSocket, echoBuffer, RCVBUFSIZE, 0)) < 0) /* Receive message from client */
    [self dieWithError:"recv() failed"];
  /* Send received string and receive again until end of transmission */
  while (recvMsgSize > 0) {/* zero indicates end of transmission */
    if (send(clntSocket, echoBuffer, recvMsgSize, 0) !=
        recvMsgSize) /* Echo message back to client */
      [self dieWithError:"send() failed"];
    if ((recvMsgSize = recv(clntSocket, echoBuffer, RCVBUFSIZE, 0)) < 0) /* See if there is more data to receive */
      [self dieWithError:"recv() failed"];
  }
  close(clntSocket); /* Close client socket */
}
- (void) dieWithError:(char*)errorMessage; /* Error handling function */
{
  perror(errorMessage); exit(1);
}

@end
