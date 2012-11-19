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
    UIButton *btnPlayStop;
    UIButton *btnRecord;
    UIButton *btnRecordStop;
    UIButton *btnProcess;
    UITextField *tf1;
    UITextField *tf2;
}

@property (readonly, nonatomic) IBOutlet audioController *audioController;

@property (retain, nonatomic) IBOutlet UITextField *tf1;

@property (retain, nonatomic) IBOutlet UITextField *tf2;

@property (retain, nonatomic) IBOutlet UIButton *btnPlay;
@property (retain, nonatomic) IBOutlet UIButton *btnPlayStop;

@property (retain, nonatomic) IBOutlet UIButton *btnRecord;
@property (retain, nonatomic) IBOutlet UIButton *btnRecordStop;
@property (retain, nonatomic) IBOutlet UIButton *btnProcess;

- (IBAction)backgroundTouched:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)playStop:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)recordStop:(id)sender;
- (IBAction)testOutput:(id)sender;

@end