//
//  ViewController.h
//  LGSideMenuControllerDemo
//

#import <UIKit/UIKit.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEEventsObserver.h>

@interface ViewController : UIViewController <OEEventsObserverDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) OEEventsObserver *openEarsEventsObserver;
@property IBOutlet UIPickerView *house;
@property (weak) IBOutlet UITextField *pass;
@property (weak) IBOutlet UITextField *pass2;
@property (nonatomic, strong) UIView *micEntry;
@property IBOutlet UILabel *uname;
@property (retain) IBOutlet UITextField *uNew;
@property (retain) IBOutlet UISwitch *pSwitch;
@property IBOutlet UITableView *tableView;

@end
