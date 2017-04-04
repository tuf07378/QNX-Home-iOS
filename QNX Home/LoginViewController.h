//
//  TableViewController.h
//  LGSideMenuControllerDemo
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, retain) IBOutlet UITextField *user;
@property (nonatomic, retain) IBOutlet UITextField *pass;
@property (nonatomic, retain) IBOutlet UITextField *userReg;
@property (nonatomic, retain) IBOutlet UITextField *regPass2;
@property (nonatomic, retain) IBOutlet UITextField *regPass;
@property (retain, readwrite) NSString *returned;

@end
