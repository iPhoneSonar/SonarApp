//
//  trViewController.h
//  sonar1
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioController.h"
#import "processing.h"

@interface trViewController : UIViewController <UITextFieldDelegate>{
    
	audioController *audioController;
    UIButton *btnPlay;
    UIButton *btnStop;
    UITextField *tf1;
    UITextField *tf2;
}

@property (readonly, nonatomic) IBOutlet audioController *audioController;

@property (retain, nonatomic) IBOutlet UITextField *tf1;

@property (retain, nonatomic) IBOutlet UITextField *tf2;

@property (retain, nonatomic) IBOutlet UIButton *btnPlay;

@property (retain, nonatomic) IBOutlet UIButton *btnStop;

- (IBAction)backgroundTouched:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)stop:(id)sender;

@end