//
//  communicator.m
//  batapp
//
//  Created by lio 123 on 19/11/2012.
//
//

#import "communicator.h"

@implementation communicator

@synthesize inputStream;
@synthesize outputStream;
@synthesize host;

const SInt16 PORT = 2000;

-(void)dealloc
{
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

void callout(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"socketCallback called");
    switch(type)
    {
        case kCFSocketNoCallBack:
            NSLog(@"kCFSocketNoCallBack");
            break;
        case kCFSocketReadCallBack:
            NSLog(@"kCFSocketReadCallBack");
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

- (SInt16)initCom
{
    //activate all available callbacks
    CFOptionFlags callBackTypes = kCFSocketReadCallBack |
                                  kCFSocketAcceptCallBack |
                                  kCFSocketDataCallBack |
                                  kCFSocketConnectCallBack |
                                  kCFSocketWriteCallBack;

    const CFSocketContext *context = NULL;
    
    CFSocketRef	pSock = CFSocketCreate(kCFAllocatorDefault,
                                       AF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       callBackTypes,
                                       callout, context);

    NSLog(@"socket %ld", (SInt32)pSock);
    
    if (pSock == NULL)
    {
        NSLog(@"error socket create");
        return -1;
    }
    
    NSLog(@"socket created successfull");

    /* Set the port and address we want to listen on*/
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);


    NSData *address = [ NSData dataWithBytes: &addr length: sizeof(addr) ];
    if (CFSocketSetAddress(pSock, (CFDataRef) &addr) != kCFSocketSuccess) {
        fprintf(stderr, "CFSocketSetAddress() failed\n");
        //CFRelease(TCPServer);
        return EXIT_FAILURE;
    }

              
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
    //NSLog(@"written: %d",bytesWritten);
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
    [inputStream close];
    [outputStream close];
}
@end
