//
//  TableViewController.m
//  LGSideMenuControllerDemo
//

#import "LoginViewController.h"
#import "MainViewController.h"

@interface LoginViewController ()

@property (strong, nonatomic) NSArray *titlesArray;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (IBAction)loginClicked:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationController"];
    
    [navigationController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"ViewController"]]];
    
    MainViewController *mainViewController = [storyboard instantiateInitialViewController];
    mainViewController.rootViewController = navigationController;
    [mainViewController setupWithType:2];
    
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    window.rootViewController = mainViewController;
    
    [UIView transitionWithView:window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:nil
                    completion:nil];
}

- (IBAction)registerClicked:(id)sender{
    UIAlertController *registration = [UIAlertController alertControllerWithTitle:@"Register Account" message:@"Enter your user account and password." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *reg = [UIAlertAction actionWithTitle:@"Register" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [registration addTextFieldWithConfigurationHandler:^(UITextField
                                                         *textField) {textField.placeholder = @"UserID";
        textField.keyboardType = UIKeyboardTypeEmailAddress;}];
    [registration addTextFieldWithConfigurationHandler:^(UITextField
                                                         *textField) {textField.placeholder = @"Password";
        textField.secureTextEntry = true;}];
    [registration addTextFieldWithConfigurationHandler:^(UITextField
                                                         *textField) {textField.placeholder = @"Password Confirmation";
        textField.secureTextEntry = true;}];
    [registration addAction:reg];
    [registration addAction:cancel];
    [self presentViewController:registration animated:YES completion:nil];
}

@end

