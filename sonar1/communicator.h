//
//  communicator.h
//  batapp
//
//  Created by lio 123 on 19/11/2012.
//
//

#import <Foundation/Foundation.h>

@interface communicator : NSObject {
NSInputStream *inputStream;
NSOutputStream *outputStream;
CFStringRef host;
}

@property(nonatomic,readonly) NSInputStream *inputStream;
@property(nonatomic,retain) NSOutputStream *outputStream;
@property(nonatomic) CFStringRef host;


- (void)initNetworkCom;
- (void)setHost: (CFStringRef)ip;
- (void)send:(NSString*)msg;
- (void)send:(NSString*)fileStr :(NSString*)fileName;
- (void)open;
- (void)close;
@end
