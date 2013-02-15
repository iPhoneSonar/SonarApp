//
//  MeasurementView.h
//  batapp
//
//  Created by lio 123 on 15/01/2013.
//
//

#import <UIKit/UIKit.h>

@interface MeasurementView : UIViewController <UITextFieldDelegate>{
    UILabel *tf1;

}
@property (retain, nonatomic) IBOutlet UILabel *tf1;

- (IBAction)switchToConfigView:(id)sender;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (void)viewDidLoad;
- (void)didReceiveMemoryWarning;
- (IBAction)startMeasurement:(id)sender;
- (void)dealloc;
- (void)viewDidUnload;


@end
