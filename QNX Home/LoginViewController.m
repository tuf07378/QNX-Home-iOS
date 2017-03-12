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
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURL *url = [NSURL URLWithString:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/login"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.user.text, @"username", self.pass.text, @"password", nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    NSLog(@"%@", mapData.allValues);
    [request setHTTPBody:postData];
    
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            // Handle error...
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            //NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
            //NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"[{\"SessionToken\":\""]){
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
        else{
            NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate:nil delegateQueue: [NSOperationQueue mainQueue]];
            
            NSURL * url = [NSURL URLWithString:[@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/checkusername/" stringByAppendingString:self.user.text]];
            
            
            NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                if(error == nil)
                                                                {
                                                                    NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                    if ([text containsString:@"0"]){
                                                                        self.pass.backgroundColor = [UIColor redColor];
                                                                    }
                                                                    else{
                                                                        self.user.backgroundColor = [UIColor redColor];
                                                                    }
                                                                }
                                                                
                                                            }];
            
            [dataTask resume];

        }
    }];
    
    [postDataTask resume];
}

- (IBAction)registerClicked:(id)sender{
    UIAlertController *registration = [UIAlertController alertControllerWithTitle:@"Register Account" message:@"Enter your user account and password." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *reg = [UIAlertAction actionWithTitle:@"Register" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate:nil delegateQueue: [NSOperationQueue mainQueue]];
        
        NSURL * url = [NSURL URLWithString:[@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/checkusername/" stringByAppendingString:self.userReg.text]];
        
        
        NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                            if(error == nil)
                                                            {
                                                                NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                if ([text containsString:@"0"]){
                                                                    UIAlertController *noReg = [UIAlertController alertControllerWithTitle:@"Not Available" message:@"Sorry, the username you selected is not available, please choose a new one." preferredStyle:UIAlertControllerStyleAlert];
                                                                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                                                                    [noReg addAction:ok];
                                                                    [self dismissViewControllerAnimated:TRUE completion:nil];
                                                                    [self presentViewController:noReg animated:YES completion:nil];
                                                                }
                                                                else{
                                                                    NSError *error;
                                                                    
                                                                    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                                                                    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
                                                                    NSURL *url = [NSURL URLWithString:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/register"];
                                                                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                                                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                                                       timeoutInterval:60.0];
                                                                    
                                                                    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                                                                    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
                                                                    
                                                                    [request setHTTPMethod:@"POST"];
                                                                    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.userReg.text, @"username", self.regPass.text, @"password", nil];
                                                                    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
                                                                    NSLog(@"%@", mapData.allValues);
                                                                    [request setHTTPBody:postData];
                                                                    
                                                                    
                                                                    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                        if (error) {
                                                                            // Handle error...
                                                                            return;
                                                                        }
                                                                        
                                                                        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                                            //NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
                                                                            //NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
                                                                        }
                                                                        
                                                                        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                                        NSLog(@"Response Body:\n%@\n", body);
                                                                        if ([body containsString:@"Successfull inserted the user into the table"]){
                                                                            NSError *error;
                                                                            
                                                                            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                                                                            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
                                                                            NSURL *url = [NSURL URLWithString:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/login"];
                                                                            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                                                                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                                                               timeoutInterval:60.0];
                                                                            
                                                                            [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                                                                            [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
                                                                            
                                                                            [request setHTTPMethod:@"POST"];
                                                                            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.userReg.text, @"username", self.regPass.text, @"password", nil];
                                                                            NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
                                                                            NSLog(@"%@", mapData.allValues);
                                                                            [request setHTTPBody:postData];
                                                                            
                                                                            
                                                                            NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                                if (error) {
                                                                                    // Handle error...
                                                                                    return;
                                                                                }
                                                                                
                                                                                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                                                    //NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
                                                                                    //NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
                                                                                }
                                                                                
                                                                                NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                                                NSLog(@"Response Body:\n%@\n", body);
                                                                                if ([body containsString:@"[{\"SessionToken\":\""]){
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
                                                                            }];
                                                                            
                                                                            [postDataTask resume];
                                                                        }
                                                                    }];
                                                                    
                                                                    [postDataTask resume];
                                                                }
                                                            }
                                                            
                                                        }];
        
        [dataTask resume];
        }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [registration addTextFieldWithConfigurationHandler:^(UITextField
                                                         *textField) {
        textField.placeholder = @"UserID";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.delegate = self;
        self.userReg = textField;
    }];
    [registration addTextFieldWithConfigurationHandler:^(UITextField
                                                         *textField) {
        textField.placeholder = @"Password";
        textField.secureTextEntry = true;
        textField.delegate = self;
        self.regPass = textField;
    }];
    [registration addTextFieldWithConfigurationHandler:^(UITextField
                                                         *textField) {
        textField.placeholder = @"Password Confirmation";
        textField.secureTextEntry = true;
        textField.delegate = self;
        self.regPass2 = textField;
    }];
    [registration addAction:reg];
    [registration addAction:cancel];
    [self presentViewController:registration animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.user) {
        [textField resignFirstResponder];
        [self.pass becomeFirstResponder];
    } else if (textField == self.pass) {
        // here you can define what happens
        // when user presses return on the email field
        [self.view endEditing:TRUE];
    }
    else if (textField == self.userReg){
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate:nil delegateQueue: [NSOperationQueue mainQueue]];
        
        NSURL * url = [NSURL URLWithString:[@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/checkusername/" stringByAppendingString:self.userReg.text]];
        
        
        NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                            if(error == nil)
                                                            {
                                                                NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                if ([text containsString:@"0"]){
                                                                    self.userReg.backgroundColor = [UIColor redColor];
                                                                }
                                                                else{
                                                                    self.userReg.backgroundColor = [UIColor greenColor];
                                                                }
                                                            }
                                                            
                                                        }];
        
        [dataTask resume];
    }
    else if (textField == self.regPass2){
        if (self.regPass2.text != self.regPass.text){
            self.regPass.backgroundColor = [UIColor redColor];
            self.regPass2.backgroundColor = [UIColor redColor];
        }else{
            self.regPass.backgroundColor = [UIColor greenColor];
            self.regPass2.backgroundColor = [UIColor greenColor];
        }
    }
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.userReg)
        [self textFieldShouldReturn:textField];
    else if (textField == self.regPass)
        [self textFieldShouldReturn:textField];
    else if (textField == self.regPass2)
        [self textFieldShouldReturn:textField];
}


@end

