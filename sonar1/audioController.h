//
//  audioController.h
//  sonar
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef audioControllerH
#define audioControllerH

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CAStreamBasicDescription.h"
#import "processing.h"
#import "communicator.h"

struct sig{
    SInt32 *buf;
    SInt32 pos;
    SInt32 len;
};
typedef struct sig sig;

typedef struct recordBuffer recordBuffer;

@interface audioController : NSObject
{
    //frequency for the sine wave
    int frequency;
    
    //recording unit
    AudioComponentInstance audioUnit;
    AudioBufferList *recordingBufferList;
    sig *recordBuf;
    sig *play;
    sig *sendSig;
    sig *zeroSig;
    communicator *com;
    processing *proc;

    UITextField *tfOutput;
    //returnvalue (^functionname) (parameter)
    SInt16 (^comRet) (NSString*);
}

@property(nonatomic) int frequency;
@property(nonatomic) AudioComponentInstance audioUnit;
@property(nonatomic) AudioBufferList *recordingBufferList;
@property(nonatomic,retain) communicator *com;
@property(nonatomic, retain) processing *proc;


- (OSStatus)audioUnitInit;
- (void)sessionInit;
- (OSStatus)start;
- (OSStatus)stop;
- (void)testOutput;

- (SInt16)sendSigInit;
- (SInt16)zeroSigInit;
- (SInt16)recordBufferInitSamples;


- (SInt16)initClient;
- (SInt16)initServer;

- (SInt16)setOutput:(UITextField**)tf;


@end
#endif
