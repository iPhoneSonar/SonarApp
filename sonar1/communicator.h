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

typedef SInt16 (^fpComReturn)(NSString*);

enum ConnectionState {
    CS_DISCONNECTED = 0,
    CS_ClIENT = 1,
    CS_SERVER = 2
};


@interface communicator : NSObject {
NSInputStream* inputStream;
NSOutputStream* outputStream;
CFStringRef host;
CFSocketRef	pSock;
int pNativeSock;
ConnectionState connectionState;
bool timestampReceived;
void* pComReturn;
SInt16 (^comRet) (NSString*); //returnvalue (^functionname) (parameter)
}


@property(nonatomic,readonly) NSInputStream* inputStream;
@property(nonatomic,retain) NSOutputStream* outputStream;
@property(nonatomic) CFStringRef host;
@property(nonatomic) CFSocketRef pSock;
@property(nonatomic) int pNativeSock;
@property(nonatomic) ConnectionState connectionState;
@property(nonatomic) bool timestampReceived;
@property(nonatomic) void* pComReturn;

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



//static void callout(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@end
#endif
