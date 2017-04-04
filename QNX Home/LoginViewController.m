//
//  TableViewController.m
//  LGSideMenuControllerDemo
//

#import "LoginViewController.h"
#import "MainViewController.h"
#import "GlobalVars.h"
#include <CommonCrypto/CommonDigest.h>

@interface LoginViewController ()

@property (strong, nonatomic) NSArray *titlesArray;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [self.navigationController setNavigationBarHidden:YES];
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background"]];
    bgImageView.frame = self.view.bounds;
    [self.view addSubview:bgImageView];
    [self.view sendSubviewToBack:bgImageView];
    [super viewDidLoad];
}

- (IBAction)loginClicked:(id)sender{
    [self.view endEditing:YES];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.user.text, @"username", [self sha256:self.pass.text], @"password", nil];
    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/login" withData:mapData];
    NSLog(@"Response Body:\n%@\n", body);
    if ([body containsString:@"[{\"SessionToken\":\""]){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSString *haystackPrefix = @"[{\"SessionToken\":\"";
        NSString *haystackSuffix = @"\"}]";
        NSRange needleRange = NSMakeRange(haystackPrefix.length,
                                              body.length - haystackPrefix.length - haystackSuffix.length);
        NSString *needle = [body substringWithRange:needleRange];
        globals.seshToke = needle;
        globals.uname = self.user.text;
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", nil];
        NSString *test = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/listhouses" withData:mapData];
        [self parseHouses:test];
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
        self.pass.backgroundColor = [UIColor redColor];
        self.user.backgroundColor = [UIColor redColor];
    }
}

- (IBAction)registerClicked:(id)sender{
    UIAlertController *registration = [UIAlertController alertControllerWithTitle:@"Register Account" message:@"Enter your user account and password." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *reg = [UIAlertAction actionWithTitle:@"Register" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        if (self.userReg.text.length > 40){
            UIAlertController *tLong = [UIAlertController alertControllerWithTitle:@"Username Too Long" message:@"Usernames must be less than 40 characters." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ret = [UIAlertAction actionWithTitle:@"Return" style:UIAlertActionStyleCancel handler:nil];
            [tLong addAction:ret];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self presentViewController:tLong animated:YES completion:nil];
        }
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate:nil delegateQueue: [NSOperationQueue mainQueue]];
        NSURL * url = [NSURL URLWithString:[@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/checkusername/" stringByAppendingString:self.userReg.text]];
        NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if(error == nil){
                NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                if ([text containsString:@"0"]){
                    UIAlertController *noReg = [UIAlertController alertControllerWithTitle:@"Not Available" message:@"Sorry, the username you selected is not available, please choose a new one." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                    [noReg addAction:ok];
                    [self dismissViewControllerAnimated:TRUE completion:nil];
                    [self presentViewController:noReg animated:YES completion:nil];
                }
            else{
                UIAlertController *regAlert = [UIAlertController alertControllerWithTitle:@"Registering" message:@"Registering new user account." preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:regAlert animated:TRUE completion:nil];
                NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.userReg.text, @"username", [self sha256:self.regPass.text], @"password", nil];
                NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/register" withData:mapData];
                NSLog(@"Response Body:\n%@\n", body);
                if ([body containsString:@"Successfull inserted the user into the table"]){
                    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.userReg.text, @"username", [self sha256:self.regPass.text], @"password", nil];
                    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/login" withData:mapData];
                    NSLog(@"Response Body:\n%@\n", body);
                    if ([body containsString:@"[{\"SessionToken\":\""]){
                        [self dismissViewControllerAnimated:TRUE completion:nil];
                        GlobalVars *globals = [GlobalVars sharedInstance];
                        globals.uname = self.userReg.text;
                        NSString *haystackPrefix = @"[{\"SessionToken\":\"";
                        NSString *haystackSuffix = @"\"}]";
                        NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
                        NSString *needle = [body substringWithRange:needleRange];
                        globals.seshToke = needle;
                        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", nil];
                        NSString *test = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/listhouses" withData:mapData];
                        [self parseHouses:test];
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                        UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"NavigationController"];
                        [navigationController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"ViewController"]]];
                        MainViewController *mainViewController = [storyboard instantiateInitialViewController];
                        mainViewController.rootViewController = navigationController;
                        [mainViewController setupWithType:2];
                        UIWindow *window = UIApplication.sharedApplication.delegate.window;
                        window.rootViewController = mainViewController;
                        [UIView transitionWithView:window duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:nil];
                    }
                }
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
    if (textField == self.userReg){
        if(self.userReg.text.length > 40){
            [self.userReg setBackgroundColor:[UIColor redColor]];
        }
        [self textFieldShouldReturn:textField];
    }
    else if (textField == self.regPass)
        [self textFieldShouldReturn:textField];
    else if (textField == self.regPass2)
        [self textFieldShouldReturn:textField];
}

-(NSString*) sha256:(NSString *)clear{
    const char *s=[clear cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *keyData=[NSData dataWithBytes:s length:strlen(s)];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH]={0};
    CC_SHA256(keyData.bytes, keyData.length, digest);
    NSData *out=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    NSString *hash=[out description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (NSString *)post:(NSString *) link withData:(NSDictionary *) data{
    NSError *error;
    dispatch_semaphore_t sem;
    NSURL *url = [[NSURL alloc] initWithString:link];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json; charset=UTF8" forHTTPHeaderField:@"Content-Type"];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    request.HTTPBody = postData;
    sem = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *error){
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.returned = body;
        dispatch_semaphore_signal(sem);
        
    }];
    
    [task resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return self.returned;
}

- (void)parseHouses:(NSString *)body{
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[{";
    NSString *haystackSuffix = @"}]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@","];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSString *house = (NSString *)houseArray[i];
        haystackPrefix = @"{\"HouseName\":\"";
        haystackSuffix = @"\"}";
        needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
        needle = [house substringWithRange:needleRange];
        GlobalVars *globals = [GlobalVars sharedInstance];
        [globals.houses addObject:needle];
    }
}

@end

