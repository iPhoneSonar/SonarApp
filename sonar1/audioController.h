//
//  audioController.h
//  sonar
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CAStreamBasicDescription.h"
#import "processing.h"
#import "communicator.h"

struct sig{
    SInt32 *buf;
    SInt32 pos;
    SInt32 len;
    SInt32 shift;
    SInt32 samplesPerPeriod;
};
typedef struct sig sig;

struct recordBuffer{
    SInt32 *buf;
    SInt32 pos;
    SInt32 len;
};
typedef struct recordBuffer recordBuffer;

@interface audioController : NSObject
{
    //frequency for the sine wave
    int frequency;
    
    //recording unit
    AudioComponentInstance audioUnit;
    AudioBufferList *recordingBufferList;
    sig *sine;
    sig *mute;
    recordBuffer record;
    sig *play;
    sig *testSweep;
    communicator *com;
}

@property(nonatomic) int frequency;
@property(nonatomic) AudioComponentInstance audioUnit;
@property(nonatomic) AudioBufferList *recordingBufferList;
@property(nonatomic,retain) communicator *com;


- (void)setFrequency:(int) value;
- (void)getFrequency:(int*) value;
- (OSStatus)audioUnitInit;
- (OSStatus)start;
- (OSStatus)stop;
- (void)testOutput;
- (void)mute:(UInt32)flag;
- (void)sineSigInit;
- (void)recordBufferInit:(SInt32)len;
- (void)recordBufferInitSamples;
- (void)muteSigInit;

@end
