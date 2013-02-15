//
//  MeasurementView.h
//  batapp
//
//  Created by lio 123 on 15/01/2013.
//
//

#import <UIKit/UIKit.h>
#import "AudioController.h"
#import "processing.h"

@interface MeasurementView : UIViewController <UITextFieldDelegate>{
    UILabel *tf1;
    audioController *audioController;

}
@property (readonly, nonatomic) IBOutlet audioController *audioController;
@property (retain, nonatomic) IBOutlet UILabel *tf1;

- (IBAction)switchToConfigView:(id)sender;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (void)viewDidLoad;
- (void)didReceiveMemoryWarning;
- (IBAction)startMeasurement:(id)sender;
- (void)dealloc;
- (void)viewDidUnload;


@end
