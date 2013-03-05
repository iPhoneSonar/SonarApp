//
//  trViewController.m
//  sonar1
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef DEBUG
//#define NSLog(...)
#endif

#import "trViewController.h"
#import "MeasurementView.h"
#import "trAppDelegate.h"

@implementation trViewController

@synthesize audioController;
@synthesize btnStart;
@synthesize btnStop;
@synthesize btnProcess;
@synthesize tfIp;
@synthesize btnConnect;
@synthesize btnNetMode;
@synthesize LabelServerIP;

- (IBAction)switchToMeasurementView:(id)sender
{
    MeasurementView *MView=[[MeasurementView alloc] initWithNibName:nil bundle:nil];
    MView.audioController=self.audioController;
    [self presentModalViewController:MView animated:NO];
}

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
    tfIp.text = [[audioController com]getLocalIP];
    LabelServerIP.text=[[audioController com]getLocalIP];
    LabelServerIP.hidden=YES;

}

- (void)dealloc {
	[audioController release];

    [btnStart release];
    [btnStop release];
    [btnProcess release];
    [tfIp release];
    [btnConnect release];
    [btnNetMode release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setBtnStart:nil];
    [self setBtnStop:nil];
    [self setBtnProcess:nil];
    [self setTfIp:nil];
    [self setBtnConnect:nil];
    [self setBtnNetMode:nil];
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
    [tfIp resignFirstResponder];
    //insert start here for start at Background touch
}

- (IBAction)start:(id)sender {

    [audioController recordBufferInitSamples];
    [audioController start];
}

- (IBAction)stop:(id)sender {
    [audioController stop];
}

- (IBAction)testOutput:(id)sender { //process button
    [audioController testOutput];
}

- (IBAction)connect:(id)sender
{
    if (btnNetMode.selected == YES) //server
    {
        return;
    }
    else
    { //must be client
        NSLog(@"btnNetMode NO");
        [[audioController com ]setHost: (CFStringRef)self.tfIp.text];
        NSLog(@"server ip = %@",[[audioController com]host]);
        if([audioController initClient] == -1)
        {
            return;
        }
        [audioController start];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == tfIp)
        [tfIp resignFirstResponder];
    return NO;
}

- (IBAction)netMode:(UIButton*)sender
{
    //NSLog(@"btnNetMode.selected %d", self.btnNetMode.selected);

    NSLog(@"selected %d", btnNetMode.selected);
    if ([[audioController com ] pSock])
    {
        [[audioController com] close];
        NSLog(@"close socket");
    }

    if (self.btnNetMode.selected == YES)
    {
        self.btnNetMode.selected = NO;
        self.tfIp.hidden = NO;
        self.btnConnect.hidden=YES;
        self.LabelServerIP.hidden=NO;
    }
    else
    {
        self.btnNetMode.selected = YES;
        self.tfIp.hidden = YES;
        self.LabelServerIP.hidden=NO;
        self.btnConnect.hidden=YES;
        
        NSLog(@"btnNetMode YES");
        [audioController initServer];
    }
}

@end
