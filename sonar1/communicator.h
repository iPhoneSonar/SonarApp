//
//  communicator.h
//  batapp
//
//  Created by lio 123 on 19/11/2012.
//
//

#import <Foundation/Foundation.h>

#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <time.h>
#import <arpa/inet.h>


@interface communicator : NSObject {
NSInputStream *inputStream;
NSOutputStream *outputStream;
CFStringRef host;
CFSocketRef	pSock;
}

@property(nonatomic,readonly) NSInputStream *inputStream;
@property(nonatomic,retain) NSOutputStream *outputStream;
@property(nonatomic) CFStringRef host;
@property(nonatomic) CFSocketRef pSock;

- (void)initNetworkCom;
- (void)setHost: (CFStringRef)ip;
- (void)send:(NSString*)msg;
- (void)send:(NSString*)fileStr :(NSString*)fileName;
- (void)open;
- (void)close;
- (SInt16)clientConnect;
- (SInt16)serverStart;

static void callout(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@end
