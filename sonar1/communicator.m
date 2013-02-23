//
//  communicator.m
//  batapp
//
//  Created by lio 123 on 19/11/2012.
//
//

#import "communicator.h"
#import <ifaddrs.h>


const SInt16 PORT = 2000;
const SInt16 DEBUG_PORT = 2002;
const CFStringRef DEBUG_HOST = (CFStringRef)@"192.168.173.1";

@implementation communicator

@synthesize timestampReceived;
@synthesize inputStream;
@synthesize outputStream;
@synthesize host;
@synthesize pSock;
@synthesize pSockNative;
@synthesize connectionState;
@synthesize pComReturn;
@synthesize receivedTimestamp;
-(communicator*)init
{
    connectionState = CS_DISCONNECTED;
    comRet = NULL;
    pSock = NULL;
    pSockNative = NULL;
    timestampReceived = false;
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
    NSLog(@"socketCallbackClient %ld called", (SInt32)s);
    //get the object pointer from the context
    CFSocketContext cfSC;
    CFSocketGetContext(s, &cfSC);
    communicator *localCom = (communicator*)cfSC.info;

    switch(type)
    {
        case kCFSocketReadCallBack:
        {
            NSLog(@"kCFSocketReadCallBack");
            const UInt16 BUFSIZE = 20;
            char sBuf[BUFSIZE];
            memset(sBuf,0,BUFSIZE);
            int iRet = 0;
            iRet = recv(localCom->pSockNative, sBuf, BUFSIZE, 0);
            if (iRet == 0)
            {
                NSLog(@"iRet == 0");
                //indication for remote closed socket
                [localCom closeNew];
                break;
            }
            NSLog(@"recv: %s",sBuf);
            //#001<distance>#
            if (strncmp(sBuf,"#001",4))
            {
                //strDistance
                //[localCom displayMsg:];
            }
            //#002calibration
            else if(strncmp(sBuf,"002",4))
            {
                        
            }
            else
            {
                NSString *strMsg = [NSString stringWithFormat:@"communicator %s",sBuf];
                localCom->comRet = (SInt16 (^)(NSString*))localCom->pComReturn;
                NSLog(@"strMsg: %@ = %d.\n",strMsg, localCom->comRet(strMsg));
                
            }
                
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

static void socketCallbackServerAccpeted(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"socketCallbackServerAccpeted %ld called", (SInt32)s);
    CFSocketContext cfSC;
    CFSocketGetContext(s, &cfSC);
    communicator *localCom = (communicator*)cfSC.info;
    CFSocketNativeHandle pSockNativeLoc = CFSocketGetNative(s);
    //this check is not realy needed as only one callback tye is defined
    if (type == kCFSocketReadCallBack)
    {
        //we have an connected client socket that will send us an timestamp

        const UInt16 BUFSIZE = 15;
        char sBuf[BUFSIZE];
        memset(sBuf,0,BUFSIZE);
        int iRet = 0;
        iRet = recv(pSockNativeLoc, sBuf, BUFSIZE, 0);
        if (iRet == 0)
        {
            NSLog(@"iRet == 0\n");
            //indication for remote closed socket
            CFSocketInvalidate(s);
            return;
        }
        else if (iRet < 0)
        {
            NSLog(@"iRet =%d.\nerrno =%d",iRet,errno);
            return;
        }
        [localCom setReceivedTimestamp: atof(sBuf)];
        NSLog(@"fTimestamp=%f.\n", [localCom receivedTimestamp]);


        //we need the socket to respond the distance after processing
        //TODO:!!! do not forget to manage closing the socket
        [localCom setPSockNative: pSockNativeLoc];
        [localCom setPSock: s];
        [localCom setTimestampReceived:true];
    }
    else
    {
        NSLog(@"error, callback type=%d.\n",(int)type);
    };
}

static void socketCallbackServer(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"socketCallbackServer %ld called", (SInt32)s);
    CFSocketContext cfSC;
    CFSocketGetContext(s, &cfSC);
    communicator *localCom = (communicator*)cfSC.info;
    [localCom closeNew];
    
    CFSocketNativeHandle pSockNativeLocal = CFSocketGetNative(s);
    if (type == kCFSocketReadCallBack)
    {
        //server
        NSLog(@"kCFSocketReadCallBack");
        //its servcer socket so this event only occurs if a client tries to connect
        struct sockaddr addr;
        socklen_t addrSize = sizeof(addr);
        memset(&addr, 0, addrSize);
        CFSocketNativeHandle pSockAccepted = NULL;
        //NSLog(@"got native handle");
        pSockAccepted = accept(pSockNativeLocal, &addr, &addrSize);
        NSLog(@"client accepted");
        //from the native socket we need to create a cfsocket objekt
        CFSocketRef cfSockAccepted =
        CFSocketCreateWithNative(kCFAllocatorDefault,
                                 pSockAccepted,
                                 kCFSocketReadCallBack,
                                 socketCallbackServerAccpeted,
                                 &cfSC);
        //NSLog(@"create from native");
        //once we have the new connected socket put it in the runloop
        
        CFRunLoopSourceRef sourceRef = 
        CFSocketCreateRunLoopSource(kCFAllocatorDefault, cfSockAccepted, 0);

        CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
        CFRelease(sourceRef);
        //NSLog(@"added to runloop");
    }
    else
    {
        NSLog(@"error, callback type=%d.\n",(int)type);
    };
}


- (SInt16)serverStart
{
    //close socket if open
    CFSocketContext context = { 0,self,NULL,NULL,NULL};
    //kCFSocketNoCallBack = 0,
    //kCFSocketReadCallBack = 1,
    //kCFSocketAcceptCallBack = 2,
    //kCFSocketDataCallBack = 3,
    //kCFSocketConnectCallBack = 4,
    //kCFSocketWriteCallBack = 8

    CFOptionFlags callBackTypes = kCFSocketReadCallBack;

    CFSocketRef pSockListen = CFSocketCreate(kCFAllocatorDefault,
                                       AF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       callBackTypes,
                                       &socketCallbackServer,
                                       &context);

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
    //fpComReturn comReturn = (fpComReturn) pComReturn;
    //comReturn(@"hello from clientConnect");
    //SInt16 (^myblock) (NSString*); //returnvalue (^functionname) (parameter)
    //myblock = (SInt16 (^)(NSString*))pComReturn;
    //NSLog(@"ret = %d.\n",myblock(@"communicator"));
    
    //close socket if open
    if (pSock)
    {
        CFSocketInvalidate(pSock);
        NSLog(@"client socket closed");
        pSock = NULL;
        pSockNative = NULL;
    }
    
    CFSocketContext clientContext = { 0,self,NULL,NULL,NULL};

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

    //setsockopt(CFSocketGetNative(pSockListen), SOL_SOCKET, SO_REUSEADDR,
    //           (void *)&flag, sizeof(flag));


    CFSocketNativeHandle pSockNativeLoc = CFSocketGetNative(pSock);

    int status = connect(pSockNativeLoc,(sockaddr*)&addr,sizeof(addr));
    
    CFSocketConnectToAddress (pSock, cfdAddr, timeout);

    if (status != kCFSocketSuccess)
    {
        NSLog(@"error CFSocketConnectToAddress");
        CFRelease(pSock);
        pSock = NULL;
        return -1;
    }

    connectionState = CS_ClIENT;
    NSLog(@"clientConnected");

    CFRunLoopSourceRef sourceRef =
    CFSocketCreateRunLoopSource(kCFAllocatorDefault, pSock, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
    CFRelease(sourceRef);

    return 0;
}

- (SInt16)sendNew: (char*)msg
{
    int iRet = 0;
    //TODO:
    //insert some kind of timeout and error handling
    pSockNative = CFSocketGetNative(pSock);
    
    if (connectionState)
    {
        iRet = send(pSockNative, msg, strlen(msg), 0);
    }
    if (iRet > 0) //reflects the length of send msg, <1 ->error
    {
        return 0; //
    }
    return iRet;
}

- (SInt16)recvNew: (char*)sBuf : (UInt16*)uiLen
{
    size_t iRet = 0;
    if (connectionState)
    {
        iRet = recv(pSockNative, sBuf, *uiLen, 0);
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
    if (pSock)
    {
        CFSocketInvalidate(pSock);
        pSockNative = NULL;
        pSock = NULL;
    }
    NSLog(@"socket closed");
}

- (NSString*)getLocalIP
{
    NSString *locIp = @"noAdd";
    ifaddrs *interfaces = NULL;
    ifaddrs *temp_addr = NULL;
    int iRet = getifaddrs(&interfaces);
    if(iRet != 0)
    {
        NSLog(@"error getifaddrs");
        return locIp;
    }
    temp_addr = interfaces;
    sockaddr *sa = (temp_addr->ifa_addr);
    while (temp_addr != NULL)
    {
        if(sa->sa_family == AF_INET)
            //check if interface is wlan (en0)
            if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqual:@"en0"])
            {
                locIp =
                [NSString stringWithUTF8String:inet_ntoa(((sockaddr_in *)sa)->sin_addr)];
                break;
            }
        temp_addr = temp_addr->ifa_next;
        sa = (temp_addr->ifa_addr);
    }
    freeifaddrs(interfaces);
    return locIp;
}

@end
