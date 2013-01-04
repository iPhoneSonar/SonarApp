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

@synthesize btnStart;
@synthesize btnStop;
@synthesize btnProcess;
@synthesize tf1;
@synthesize tf2;
@synthesize tfIp;
@synthesize btnConnect;
@synthesize btnMute;

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
    [audioController audioUnitInit];
       
    //[audioController initializeAUGraph];

}

- (void)dealloc {
	[audioController release];
    
    [btnStart release];
    [btnStop release];
    [tf1 release];
    [tf2 release];
    [btnProcess release];
    [tfIp release];
    [btnConnect release];
    [btnMute release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setBtnStart:nil];
    [self setBtnStop:nil];
    [self setTf1:nil];
    [self setTf2:nil];
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
    //insert start here for start at Background touch
}

- (IBAction)start:(id)sender {
    //can be added to backgroundTouched
    NSString *strRecordLen = self.tf1.text;
    NSCharacterSet *decimalSet = [NSCharacterSet decimalDigitCharacterSet];
    NSString *temp = [strRecordLen stringByTrimmingCharactersInSet:decimalSet];
    if (temp.length == 0)
    {
        UInt16 value = [strRecordLen intValue];
        if (value > 0)
        {
            //Init Buffer with Frame length insertet in tb1
            //[audioController recordBufferInit:value];            
        }
        else
        {
            //Init Buffer with length of send Signal
            [audioController recordBufferInitSamples];
        }
    }
    [audioController start];
    self.tf2.text = @"start";
}

- (IBAction)stop:(id)sender {
    [audioController stop];
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
        self.tf2.text = @"playing";
    }
    else
    {
        self.btnMute.selected = YES;
        [audioController mute:0];
        self.tf2.text = @"muted";
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
