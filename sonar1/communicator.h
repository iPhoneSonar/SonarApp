//
//  communicator.h
//  batapp
//
//  Created by lio 123 on 19/11/2012.
//
//
#ifndef communicatorH
#define communicatorH

#import <Foundation/Foundation.h>

#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <time.h>
#import <arpa/inet.h>

enum ConnectionState {
    CS_DISCONNECTED = 0,
    CS_ClIENT = 1,
    CS_SERVER = 2
};


@interface communicator : NSObject {
NSInputStream *inputStream;
NSOutputStream *outputStream;
CFStringRef host;
CFSocketRef	pSock;
int pNativeSock;
ConnectionState connectionState;
bool timestampReceived;
}


@property(nonatomic,readonly) NSInputStream *inputStream;
@property(nonatomic,retain) NSOutputStream *outputStream;
@property(nonatomic) CFStringRef host;
@property(nonatomic) CFSocketRef pSock;
@property(nonatomic) int pNativeSock;
@property(nonatomic) ConnectionState connectionState;
@property(nonatomic) bool timestampReceived;

- (void)initNetworkCom;
- (void)setHost1: (CFStringRef)ip;
- (void)send:(NSString*)msg;
- (void)send:(NSString*)fileStr :(NSString*)fileName;
- (void)open;
- (void)close;
- (SInt16)clientConnect;
- (SInt16)serverStart;
- (SInt16)recvNew: (char*)sBuf : (UInt16*)uiLen;
- (SInt16)sendNew: (char*)msg;
- (void)closeNew;

@end
#endif
