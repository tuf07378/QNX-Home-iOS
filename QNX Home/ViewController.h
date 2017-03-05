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

@interface ViewController : UIViewController <OEEventsObserverDelegate>

@property (strong, nonatomic) OEEventsObserver *openEarsEventsObserver;
@property IBOutlet UILabel *text;
@property IBOutlet UIView *page;
@property (nonatomic, strong) UIView *micEntry;
@end
