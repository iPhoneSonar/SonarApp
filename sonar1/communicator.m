//
//  communicator.m
//  batapp
//
//  Created by lio 123 on 19/11/2012.
//
//

#import "communicator.h"


const SInt16 PORT = 2000;

@implementation communicator

@synthesize inputStream;
@synthesize outputStream;
@synthesize host;
@synthesize pSock;


-(void)dealloc
{
    CFRelease(inputStream);
    CFRelease(outputStream);
    CFRelease(host);
    [super dealloc];
}

- (void)initNetworkCom
{
    NSLog(@"init network");
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, host, PORT, &readStream, &writeStream);
    inputStream = (NSInputStream *)readStream;
    outputStream = (NSOutputStream *)writeStream;

    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    NSLog(@"communicator started");
}


static void callout(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"socketCallback %ld called", (SInt32)s);
    switch(type)
    {
        case kCFSocketNoCallBack:
            NSLog(@"kCFSocketNoCallBack");
            break;
        case kCFSocketReadCallBack:
            NSLog(@"kCFSocketReadCallBack");
            break;
        case kCFSocketAcceptCallBack:
        {
            NSLog(@"kCFSocketAcceptCallBack");
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
            break;
        }
        case kCFSocketDataCallBack:
            NSLog(@"kCFSocketDataCallBack");
            break;
        case kCFSocketConnectCallBack:
        {
            NSLog(@"kCFSocketConnectCallBack");
            int pNativeSock = CFSocketGetNative(s);
            const UInt16 BUFSIZE = 15;
            char sBuf[BUFSIZE];
            memset(sBuf,0,BUFSIZE);
            struct timeval tv;
            memset(&tv, 0, sizeof(struct timeval));
            tv.tv_sec = 30;
            setsockopt(pNativeSock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(struct timeval));
            //recv the timestamp
            recv(pNativeSock, sBuf, BUFSIZE, 0);
            NSLog(@"recv: %s",sBuf);
            //send one back
            memset(&tv, 0, sizeof(struct timeval));
            time_t siTimestamp = time(NULL);
            sprintf(sBuf, "%ld", siTimestamp);
            send(pNativeSock, sBuf, strlen(sBuf), 0);
            NSLog(@"timestamp send: %s",sBuf);
            break;
        }
        case kCFSocketWriteCallBack:
            NSLog(@"kCFSocketWriteCallBack");
            break;
    };
}


- (SInt16)serverStart
{
    //it makes no sence to combine callbacktypes as thay have special consequences
    //CFOptionFlags callBackTypes = kCFSocketReadCallBack |
    //                              kCFSocketAcceptCallBack |
    //                              kCFSocketDataCallBack |
    //                              kCFSocketConnectCallBack |
    //                              kCFSocketWriteCallBack;

    const CFSocketContext *context = NULL;
    
    CFSocketRef pSockListen = CFSocketCreate(kCFAllocatorDefault,
                                       AF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       kCFSocketAcceptCallBack,
                                       &callout,
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
    if (CFSocketSetAddress(pSockListen, cfdAddr) != kCFSocketSuccess) {
        NSLog(@"error CFSocketSetAddress");
        CFRelease(pSockListen);
        return -1;
    }

    CFRunLoopSourceRef sourceRef =
    CFSocketCreateRunLoopSource(kCFAllocatorDefault, pSockListen, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
    CFRelease(sourceRef);

    NSLog(@"server started");

    return 0;
}


- (SInt16)clientConnect
{
    //activate all available callbacks
    //kCFSocketReadCallBack |
    //kCFSocketAcceptCallBack |
    //kCFSocketDataCallBack |
    //kCFSocketConnectCallBack |
    //kCFSocketWriteCallBack;

    const CFSocketContext *context = NULL;

    pSock = CFSocketCreate(kCFAllocatorDefault,
                                       AF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       kCFSocketConnectCallBack,
                                       callout, context);

    NSLog(@"socket %ld", (SInt32)pSock);

    if (pSock == NULL)
    {
        NSLog(@"error socket create");
        return -1;
    }

    NSLog(@"socket created successfull");

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

    CFSocketError status = CFSocketConnectToAddress (pSock,
                                                     cfdAddr,
                                                     -1);

    if (status != kCFSocketSuccess)
    {
        NSLog(@"error CFSocketConnectToAddress");
        CFRelease(pSock);
        return -1;
    NSData *address = [ NSData dataWithBytes: &addr length: sizeof(addr) ];
    if (CFSocketSetAddress(pSock, (CFDataRef) &addr) != kCFSocketSuccess) {
        fprintf(stderr, "CFSocketSetAddress() failed\n");
        //CFRelease(TCPServer);
        return EXIT_FAILURE;
    }

    CFRunLoopSourceRef sourceRef =
    CFSocketCreateRunLoopSource(kCFAllocatorDefault, pSock, 0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
    CFRelease(sourceRef);

    return 0;
}



- (void)setHost: (CFStringRef)ip
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
        //NSLog(@"close stream");
        
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
    CFSocketInvalidate(pSock);
    NSLog(@"socket closed");
}
@end
