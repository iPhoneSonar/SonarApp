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


@interface audioController : NSObject
{
    // Audio Graph Members
    AUGraph mGraph;
    AudioUnit mMixer;
    
    // Audio Stream Description
    CAStreamBasicDescription outputCASBD;
    
    // Sine Wave Phase marker
    double sinPhase;
    
    //frequency for the sine wave
    int frequency;
}

@property(nonatomic) AUGraph mGraph;
@property(nonatomic) AudioUnit mMixer;
@property(nonatomic) CAStreamBasicDescription outputCASBD;
@property(nonatomic) double sinPhase;
@property(nonatomic) int frequency;


- (void)initializeAUGraph;
- (void)startAUGraph;
- (void)stopAUGraph;
- (void)setFrequency:(int) value;
- (void)getFrequency:(int*) value;


@end
