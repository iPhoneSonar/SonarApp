//
//  MeasurementView.m
//  batapp
//
//  Created by lio 123 on 15/01/2013.
//
//

#import "MeasurementView.h"
#import "trViewController.h"

@implementation MeasurementView

@synthesize tf1;

- (IBAction)switchToConfigView:(id)sender
{
    trViewController *trView=[[trViewController alloc] initWithNibName:nil bundle:nil];
    [self presentModalViewController:trView animated:NO];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startMeasurement:(id)sender
{
    self.tf1.text = @"startet";
}

- (void)dealloc {
    [tf1 release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setTf1:nil];
    [super viewDidUnload];
}
@end
