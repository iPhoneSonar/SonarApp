//
//  communicator.m
//  batapp
//
//  Created by lio 123 on 19/11/2012.
//
//

#import "communicator.h"


const SInt16 PORT = 2000;
const SInt16 DEBUG_PORT = 2002;
const CFStringRef DEBUG_HOST = (CFStringRef)@"192.168.173.1";

@implementation communicator

@synthesize timestampReceived;
@synthesize inputStream;
@synthesize outputStream;
@synthesize host;
@synthesize pSock;
@synthesize pNativeSock;
@synthesize connectionState;


-(communicator*)init
{
    connectionState = CS_DISCONNECTED;
    return self;
}

-(void)dealloc
{
    CFRelease(inputStream);
    CFRelease(outputStream);
    CFRelease(host);
    [super dealloc];
}

- (void)initNetworkCom
{
    NSLog(@"init debug network");
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, DEBUG_HOST, DEBUG_PORT, &readStream, &writeStream);
    inputStream = (NSInputStream *)readStream;
    outputStream = (NSOutputStream *)writeStream;

    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    

    NSLog(@"communicator started");
}

static void socketCallbackClient(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"socketCallback %ld called", (SInt32)s);
    //get the object pointer from the context
    CFSocketContext cfSC;
    CFSocketGetContext(s, &cfSC);
    communicator *localCom = (communicator*)cfSC.info;

    switch(type)
    {
        case kCFSocketReadCallBack:
        {
            NSLog(@"kCFSocketReadCallBack");
            const UInt16 BUFSIZE = 15;
            char sBuf[BUFSIZE];
            memset(sBuf,0,BUFSIZE);
            int iRet = 0;
            iRet = recv(localCom.pNativeSock, sBuf, BUFSIZE, 0);
            if (iRet == 0)
            {
                NSLog(@"iRet == 0");
                break;
            }

            NSLog(@"recv: %s",sBuf);
            break;
        }
        case kCFSocketNoCallBack:
            NSLog(@"kCFSocketNoCallBack");
            break;
        case kCFSocketAcceptCallBack:
            NSLog(@"kCFSocketAcceptCallBack");
            break;
        case kCFSocketDataCallBack:
            NSLog(@"kCFSocketDataCallBack");
            break;
        case kCFSocketConnectCallBack:
            NSLog(@"kCFSocketConnectCallBack");
            break;
        case kCFSocketWriteCallBack:
            NSLog(@"kCFSocketWriteCallBack");
            break;
    };

}


static void socketCallbackServer(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"socketCallback %ld called", (SInt32)s);
    switch(type)
    {
        case kCFSocketNoCallBack:
            NSLog(@"kCFSocketNoCallBack");
            break;
        case kCFSocketReadCallBack:
        {
            NSLog(@"kCFSocketReadCallBack");
            int pNativeSock = CFSocketGetNative(s);
            const UInt16 BUFSIZE = 15;
            char sBuf[BUFSIZE];
            memset(sBuf,0,BUFSIZE);
            struct timeval tv;
            memset(&tv, 0, sizeof(struct timeval));
            tv.tv_sec = 30;
            //recv the timestamp
            recv(pNativeSock, sBuf, BUFSIZE, 0);
            if (strlen(sBuf) == 0)
            {
                CFSocketInvalidate(s);
                s = NULL;
                NSLog(@"remote socket closed");
                break;
            }

            NSLog(@"recv: %s",sBuf);
            //send one back
            memset(&tv, 0, sizeof(struct timeval));
            time_t siTimestamp = time(NULL);
            sprintf(sBuf, "%ld", siTimestamp);
            send(pNativeSock, sBuf, strlen(sBuf), 0);
            NSLog(@"send: %s",sBuf);
            break;
        }
        case kCFSocketAcceptCallBack:
        {
            //server
            NSLog(@"kCFSocketAcceptCallBack");
            //received the timestamp
            //imitialy stop the recording
            //cyclicKkf
            //latency, distance calc
            

            /*
            int pNativeSock = *(CFSocketNativeHandle*)data;
            const UInt16 BUFSIZE = 15;
            char sBuf[BUFSIZE];
            
            time_t siTimestamp = time(NULL);
            sprintf(sBuf, "%ld", siTimestamp);
            //on connect send the timestamp
            send(pNativeSock, sBuf, strlen(sBuf), 0);
            NSLog(@"send = %s",sBuf);
            
            //wait max 30 seconds for an answer
            struct timeval tv;
            memset(&tv, 0, sizeof(struct timeval));
            tv.tv_sec = 30;
            setsockopt(pNativeSock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(struct timeval));
            memset(sBuf, 0, BUFSIZE);
            recv(pNativeSock, sBuf, BUFSIZE, 0);
            NSLog(@"recv = %s",sBuf);
            */
            break;
        }
        case kCFSocketDataCallBack:
            NSLog(@"kCFSocketDataCallBack");
            break;
        case kCFSocketConnectCallBack:
        {
            NSLog(@"kCFSocketConnectCallBack");
            break;
        }
        case kCFSocketWriteCallBack:
            NSLog(@"kCFSocketWriteCallBack");
            break;
    };
}


- (SInt16)serverStart
{
    //close socket if open
    const CFSocketContext *context = NULL;

    //kCFSocketNoCallBack = 0,
    //kCFSocketReadCallBack = 1,
    //kCFSocketAcceptCallBack = 2,
    //kCFSocketDataCallBack = 3,
    //kCFSocketConnectCallBack = 4,
    //kCFSocketWriteCallBack = 8

    CFOptionFlags callBackTypes = kCFSocketAcceptCallBack;

    CFSocketRef pSockListen = CFSocketCreate(kCFAllocatorDefault,
                                       AF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       callBackTypes,
                                       &socketCallbackServer,
                                       context);

    NSLog(@"socket %ld", (SInt32)pSockListen);

    if (pSockListen == NULL)
    {
        NSLog(@"error socket create");
        return -1;
    }
    
    NSLog(@"socket created successfull");

    //local addr reuse
    SInt32 flag = 1;
    setsockopt(CFSocketGetNative(pSockListen), SOL_SOCKET, SO_REUSEADDR,
               (void *)&flag, sizeof(flag));

    

    // Set the port and address we want to listen on
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    CFDataRef cfdAddr = CFDataCreate(NULL, (UInt8 *)&addr, sizeof(struct sockaddr_in));

    // NSData *address = [ NSData dataWithBytes: &addr length: sizeof(addr) ];
    if (CFSocketSetAddress(pSockListen, cfdAddr) != kCFSocketSuccess)
    {
        NSLog(@"error CFSocketSetAddress");
        CFRelease(pSockListen);
        pSockListen = NULL;
        return -1;
    }

    CFRunLoopSourceRef sourceRef =
    CFSocketCreateRunLoopSource(kCFAllocatorDefault, pSockListen, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
    CFRelease(sourceRef);

    connectionState = CS_SERVER;
    NSLog(@"server started");

    return 0;
}


- (SInt16)clientConnect
{
    //close socket if open
    CFSocketContext clientContext = { 0,self,NULL,NULL,NULL};
    //typedef struct {
    //    CFIndex	version;
    //    void *	info;
    //    const void *(*retain)(const void *info);
    //    void	(*release)(const void *info);
    //    CFStringRef	(*copyDescription)(const void *info);
    //} CFSocketContext;

    //kCFSocketNoCallBack = 0,
    //kCFSocketReadCallBack = 1,
    //kCFSocketAcceptCallBack = 2,
    //kCFSocketDataCallBack = 3,
    //kCFSocketConnectCallBack = 4,
    //kCFSocketWriteCallBack = 8

    CFOptionFlags callBackTypes = kCFSocketReadCallBack;
    
    pSock = CFSocketCreate(kCFAllocatorDefault,
                                       AF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       callBackTypes,
                                       socketCallbackClient,
                                        &clientContext);

    NSLog(@"socket %ld", (SInt32)pSock);

    if (pSock == NULL)
    {
        NSLog(@"error socket create");
        return -1;
    }

    NSLog(@"socket created successfull");

    pNativeSock = CFSocketGetNative(pSock);
    struct timeval tv;
    memset(&tv, 0, sizeof(struct timeval));
    tv.tv_sec = 30;
    setsockopt(pNativeSock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(struct timeval));

    // Set the port and address we want to listen on
    char sAddr[16];
    memset(sAddr,0,16);
    CFStringGetCString(host, sAddr, 16, kCFStringEncodingUTF8);

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = inet_addr(sAddr);
                           
    CFDataRef cfdAddr = CFDataCreate(NULL, (UInt8 *)&addr, sizeof(struct sockaddr_in));
    CFTimeInterval timeout = 30.0;

    CFSocketError status = CFSocketConnectToAddress (pSock,
                                                     cfdAddr,
                                                     timeout);


    if (status != kCFSocketSuccess)
    {
        NSLog(@"error CFSocketConnectToAddress");
        CFRelease(pSock);
        pSock = NULL;
        return -1;
    }

    connectionState = CS_ClIENT;
    
    //client socket is blocking
    CFRunLoopSourceRef sourceRef =
    CFSocketCreateRunLoopSource(kCFAllocatorDefault, pSock, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
    CFRelease(sourceRef);

    NSLog(@"clientConnected");
    return 0;
}

- (SInt16)sendNew: (char*)msg
{
    int iRet = 0;
    if (connectionState)
    {
        iRet = send(pNativeSock, msg, strlen(msg), 0);
    }
    if (iRet > 0)
    {
        return 0;
    }
    return iRet;
}

- (SInt16)recvNew: (char*)sBuf : (UInt16*)uiLen
{
    size_t iRet = 0;
    if (connectionState)
    {
        iRet = recv(pNativeSock, sBuf, *uiLen, 0);
    }
    
    if (iRet > 0)
    {
        *uiLen = iRet;
        return 0;
    }

    *uiLen = 0;
    return iRet;
}




- (void)setHost1: (CFStringRef)ip
{
    NSLog(@"set ip");
    host = ip;
}

- (void)send:(NSString*)msg
{
    bool flagWasOpen = true;
    //NSLog(@"[outputStream streamStatus] = %d",(int)[outputStream streamStatus]);
    if ([outputStream streamStatus] == NSStreamStatusClosed)
    {
        [self open];
        flagWasOpen = false;
        //NSLog(@"open stream");
    }
	NSData *data = [[NSData alloc] initWithData:[msg dataUsingEncoding:NSASCIIStringEncoding]];
    uint8_t *dataBytes = (uint8_t*)[data bytes];
	NSInteger bytesWritten = [outputStream write:dataBytes maxLength:[data length]];
    if (bytesWritten == 0)
    {
        NSLog(@"bytesWritten = 0");
    }
    if (flagWasOpen == false)
    {
        [self close];        
    }
}

- (void)send:(NSString*)fileStr :(NSString*)fileName
{
    [self open];
    [self send:[@"fileName:" stringByAppendingFormat:@"%@\n",fileName]];
    [self send:[fileStr stringByAppendingString:@"\n"]];
    [self send:@"fileEnd\n"];
    [self close];
}

- (void)open
{
    [inputStream open];
    [outputStream open];
}

- (void)close
{
    [inputStream close];
    [outputStream close];
    NSLog(@"stream closed");
}

- (void)closeNew
{
    CFSocketInvalidate(pSock);
    pSock = NULL;
    NSLog(@"socket closed");
}

@end
