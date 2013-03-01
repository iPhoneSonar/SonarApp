//
//  trAppDelegate.h
//  sonar1
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "audioController.h"

@class trViewController;

@interface trAppDelegate : UIResponder <UIApplicationDelegate> {

    audioController *paC;

}

@property (nonatomic,retain) audioController *paC;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) trViewController *viewController;

-(audioController*)returnAudioControllerPointer;

@end