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

    UIButton *btnStart;
    UIButton *btnStop;
    UIButton *btnProcess;
    UIButton *btnNetMode;
    UITextField *tf1;
    UITextField *tf2;
}

@property (readonly, nonatomic) IBOutlet audioController *audioController;

@property (retain, nonatomic) IBOutlet UITextField *tf1;

@property (retain, nonatomic) IBOutlet UITextField *tf2;

@property (retain, nonatomic) IBOutlet UIButton *btnStart;
@property (retain, nonatomic) IBOutlet UIButton *btnStop;
@property (retain, nonatomic) IBOutlet UIButton *btnProcess;
@property (retain, nonatomic) IBOutlet UITextField *tfIp;
@property (retain, nonatomic) IBOutlet UIButton *btnConnect;
@property (retain, nonatomic) IBOutlet UIButton *btnNetMode;

- (IBAction)connect:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)testOutput:(id)sender;
- (IBAction)netMode:(id)sender;
- (IBAction)switchToMeasurementView:(id)sender;


@end