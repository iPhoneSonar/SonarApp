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
typedef SInt16 (^fpStart)(void);

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
    Float64 fTDifSum;
    SInt32 siTDifCount;
    
    UInt64 *uiTimestamp;
    UInt64 *uiTimestampRecv;
    UInt16 *uiFramePosRecv;
    UInt16 uiPos;
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
@property(nonatomic, copy) fpStart fStart;

@property(nonatomic) UInt64 *uiTimestamp;
@property(nonatomic) UInt64 *uiTimestampRecv;
@property(nonatomic) UInt16 *uiFramePosRecv;
@property(nonatomic) UInt16 uiPos;

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
- (UInt64) getTimestampUsec;


@end
#endif
