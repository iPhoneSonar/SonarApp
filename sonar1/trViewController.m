//
//  trViewController.m
//  sonar1
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef DEBUG
#define NSLog(...)
#endif

#import "trViewController.h"
#import "fileOps.h"

@implementation trViewController

@synthesize audioController;
@synthesize btnPlay;
@synthesize btnPlayStop;
@synthesize btnRecord;
@synthesize btnRecordStop;
@synthesize btnProcess;
@synthesize tf1;
@synthesize tf2;
@synthesize tfIp;
@synthesize btnConnect;
@synthesize btnMute;

float ARecord[NSAMPLE];
float ASend[NSAMPLE];
float AKkf[KKFSIZE];

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    CreateSendSignal(ASend);
    
    [audioController initializeAUGraph];
    [audioController audioUnitInit];}

- (void)dealloc {
	[audioController release];
    
    [btnPlay release];
    [btnPlayStop release];
    [tf1 release];
    [tf2 release];
    [btnRecord release];
    [btnRecordStop release];
    [btnProcess release];
    [tfIp release];
    [btnConnect release];
    [btnMute release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setBtnPlay:nil];
    [self setBtnPlayStop:nil];
    [self setTf1:nil];
    [self setTf2:nil];
    [self setBtnRecord:nil];
    [self setBtnRecordStop:nil];
    [self setBtnProcess:nil];
    [self setTfIp:nil];
    [self setBtnConnect:nil];
    [self setBtnMute:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (IBAction)backgroundTouched:(id)sender
{
    [tf1 resignFirstResponder];
}


- (IBAction)play:(id)sender {
    int freq = 0;
    freq = [self.tf1.text intValue];
    [audioController setFrequency: freq];
    [audioController startAUGraph];
    
    //create simulated receive signal
    for (int i=0;i<NSAMPLE;i++)
    {
        ARecord[i]=0;
    }
    for (int i=280;i<NSAMPLE;i++)
    {
        ARecord[i]=ASend[i-280];
    }
    #ifndef NODEBUG
    NSLog(@"Test Empfangssignal in trViewController erzeugt");
    #endif
    
    
    
    NSLog(@"%@%@", @"play freq=", self.tf1.text);
    self.tf2.text = @"play";
}

- (IBAction)playStop:(id)sender {
    int freq = 0;
    [audioController getFrequency: &freq];
    self.tf1.text = [NSString stringWithFormat: @"%d", freq];

    [audioController stopAUGraph];
    NSLog(@"%@%@", @"stop freq=", self.tf1.text);
    self.tf2.text = @"stop";
}

- (IBAction)record:(id)sender {
    int freq = 0;
    freq = [self.tf1.text intValue];
    [audioController setFrequency: freq];
    [audioController recordingStart];
    self.tf2.text = @"recording";
}

- (IBAction)recordStop:(id)sender {
    [audioController recordingStop];
    self.tf2.text = @"stop";
}

- (IBAction)testOutput:(id)sender {
    [audioController testOutput];
    self.tf2.text = @"test out";
}

- (IBAction)mute:(id)sender {
    if (self.btnMute.selected == YES)
    {
        self.btnMute.selected = NO;
        [audioController mute:1];
    }
    else
    {
        self.btnMute.selected = YES;
        [audioController mute:0];
    }
}

- (IBAction)connect:(id)sender
{
    [[audioController com ]setHost: (CFStringRef)self.tfIp.text];
    [[audioController com ]initNetworkCom];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == tf1)
        [tf1 resignFirstResponder];
    return NO;
}




@end
