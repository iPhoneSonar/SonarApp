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
