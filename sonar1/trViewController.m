//
//  trViewController.m
//  sonar1
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "trViewController.h"
#import "fileOps.h"

@implementation trViewController

@synthesize audioController;
@synthesize btnPlay;
@synthesize btnPlayStop;
@synthesize btnRecord;
@synthesize btnRecordStop;
@synthesize tf1;
@synthesize tf2;

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
    [audioController initializeAUGraph];
}

- (void)dealloc {
	[audioController release];
    
    [btnPlay release];
    [btnPlayStop release];
    [tf1 release];
    [tf2 release];
    [btnRecord release];
    [btnRecordStop release];
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
    
    float ARecord[NSAMPLE];
    float ASend[NSAMPLE];
    float AKkf[KKFSIZE];
    
    
    CreateSendSignal(ASend);
    
    
    //Erzeugung eines simulierten Empfangssignales für KKF
    for (int i=0;i<NSAMPLE;i++)
    {
        ARecord[i]=0;
    }
    for (int i=280;i<NSAMPLE;i++)
    {
        ARecord[i]=ASend[i-280];
    }
    NSLog(@"Test Empfangssignal in trViewController erzeugt");
    
    KKF(ARecord, ASend, AKkf);
    MaximumSuche(AKkf);
    
    
    //////////////
    // Export Arrays for Signal debugging
    //
    fileOps *FRecord = [[fileOps alloc] init];
    NSMutableString *SRecord= [NSString stringWithFormat:@"%@", [FRecord FloatArrayToString:ASend OfArraySize:NSAMPLE]];
    [FRecord WriteString:[SRecord mutableCopy] ToFile:@"Record.txt"];
    
    fileOps *FKKF = [[fileOps alloc] init];
    NSMutableString *SKKF= [NSString stringWithFormat:@"%@", [FKKF FloatArrayToString:ASend OfArraySize:NSAMPLE]];
    [FKKF WriteString:[SKKF mutableCopy] ToFile:@"KKF.txt"];
    //
    // \Export Arrays for Signal debugging
    //////////////
    
    
    [audioController startAUGraph];
    NSLog(@"%@%@", @"play freq=", self.tf1.text);
    fileOps *file = [[fileOps alloc] init];
    [file WriteString:[@"play\n" mutableCopy] ToFile:@"log.txt"];
    self.tf2.text = @"play";
}

- (IBAction)playStop:(id)sender {
    int freq = 0;
    [audioController getFrequency: &freq];
    self.tf1.text = [NSString stringWithFormat: @"%d", freq];

    [audioController stopAUGraph];
    NSLog(@"%@%@", @"stop freq=", self.tf1.text);
    fileOps *file = [[fileOps alloc] init];
    [file WriteString:[@"Stop\n" mutableCopy] ToFile:@"log.txt"];
    self.tf2.text = @"stop";
}

- (IBAction)record:(id)sender {
}

- (IBAction)recordStop:(id)sender {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == tf1)
        [tf1 resignFirstResponder];
    return NO;
}




@end
