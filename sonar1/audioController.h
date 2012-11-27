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



@interface audioController : NSObject
{
    //frequency for the sine wave
    int frequency;
    
    //recording unit
    AudioComponentInstance audioUnit;
    AudioBufferList *recordingBufferList;
    AudioBufferList *chirpBufferList;
    AudioBufferList *testSin;
    
    communicator *com;
}

@property(nonatomic) int frequency;
@property(nonatomic) AudioComponentInstance audioUnit;
@property(nonatomic) AudioBufferList *recordingBufferList;
@property(nonatomic) AudioBufferList *chirpBufferList;
@property(nonatomic) AudioBufferList *testSin;
@property(nonatomic,retain) communicator *com;


- (void)setFrequency:(int) value;
- (void)getFrequency:(int*) value;
- (OSStatus)audioUnitInit;
- (OSStatus)start;
- (OSStatus)stop;
- (void)testOutput;
- (void)sinGen;
- (void)mute:(UInt32)flag;



@end
