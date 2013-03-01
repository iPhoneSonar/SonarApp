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

//prepare function pointers
typedef SInt16 (^fpComReturn)(NSString*);
typedef SInt16 (^fpDoProc)(void);

enum ConnectionState {
    CS_DISCONNECTED = 0,
    CS_ClIENT = 1,
    CS_SERVER = 2,
};


@interface communicator : NSObject {
NSInputStream* inputStream;
NSOutputStream* outputStream;
CFStringRef host;
CFSocketRef	pSock;
CFSocketNativeHandle pSockNative;
ConnectionState connectionState;
bool timestampReceived;
Float64 receivedTimestamp;
fpComReturn fComReturn;
fpDoProc fDoProc;
}


@property(nonatomic,readonly) NSInputStream* inputStream;
@property(nonatomic,retain) NSOutputStream* outputStream;
@property(nonatomic) CFStringRef host;
@property(nonatomic) CFSocketRef pSock;
@property(nonatomic) CFSocketNativeHandle pSockNative;
@property(nonatomic) ConnectionState connectionState;
@property(nonatomic) bool timestampReceived;
@property(nonatomic) Float64 receivedTimestamp;
@property(nonatomic, copy) fpComReturn fComReturn;
@property(nonatomic, copy) fpDoProc fDoProc;

- (void)initNetworkCom;
- (void)send:(NSString*)msg;
- (void)send:(NSString*)fileStr :(NSString*)fileName;
- (void)open;
- (void)close;
- (SInt16)clientConnect;
- (SInt16)serverStart;
- (SInt16)recvNew: (char*)sBuf : (UInt16*)uiLen;
- (SInt16)sendNew: (char*)msg;
- (void)closeNew;
- (NSString*)getLocalIP;



@end
#endif
