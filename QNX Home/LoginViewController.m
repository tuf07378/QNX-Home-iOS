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

- (void)loadAccount{
    
}

- (IBAction)loginClicked:(id)sender{
    [self.view endEditing:YES];
    UIAlertController *login = [UIAlertController alertControllerWithTitle:@"Logging In" message:@"Logging in and downloading user data." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:login animated:YES completion:^{
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.user.text, @"username", [self sha256:self.pass.text], @"password", nil];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/login" withData:mapData isAsync:NO];
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
            NSString *test = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/listhouses" withData:mapData isAsync:NO];
            [self parseHouses:test];
            globals.houseData = (NSMutableDictionary *) [self getSensorData];
            NSMutableDictionary *allData = [[NSMutableDictionary alloc] init];
            NSMutableArray *words = [NSMutableArray arrayWithObjects:@"Dashboard", @"Sensors", @"Relays", @"Cameras", nil];
            NSMutableDictionary *cams = [[NSMutableDictionary alloc] init];
            for (NSString *house in globals.houses){
                mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", house, @"houseName", nil];
                NSString *received = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/getcurrentperipheralsbyhouse" withData:mapData isAsync:NO];
                NSMutableArray *periphs;
                if (![received isEqualToString:@"[[]]"] && ![received isEqualToString:@"{\"message\":null}"]){
                    periphs = (NSMutableArray *)[self parsePeripherals:received];
                }
                else{
                    periphs = [[NSMutableArray alloc] init];
                }
                mapData = [[NSDictionary alloc] initWithObjectsAndKeys: house, @"HouseName", globals.seshToke, @"SessionToken", nil];
                received = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/getboardsbyhouse" withData:mapData isAsync:NO];
                NSMutableArray *boards;
                if (![received isEqualToString:@"[[]]"] && ![received isEqualToString:@"{\"message\":null}"]){
                    boards = (NSMutableArray *)[self parseBoards:received];
                }
                else{
                    boards = [[NSMutableArray alloc] init];
                }
                [allData setObject:[NSArray arrayWithObjects:periphs, boards, nil] forKey:house];
                for (int i = 0; i < [periphs count]; i+=4){
                    NSString *periph = [periphs objectAtIndex:i];
                    if ([periphs[[periphs indexOfObject:periph] + 3] isEqualToString:@"Sensor"]){
                        [words addObject:[NSString stringWithFormat:@"%@ %@ %@", house, @"Show", periph]];
                    }
                    else if ([periphs[[periphs indexOfObject:periph] + 3] isEqualToString:@"Relay"]){
                        [words addObject:[NSString stringWithFormat:@"%@ %@ %@", house, @"Turn On", periph]];
                        [words addObject:[NSString stringWithFormat:@"%@ %@ %@", house, @"Turn Off", periph]];
                    }
                    else{
                        [words addObject:[NSString stringWithFormat:@"%@ %@ %@", house, @"Show", periph]];
                    }
                }

            }
            globals.commands = words;
            globals.allData = allData;
            mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", nil];
            body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/getperipheraltypes/" withData:mapData isAsync:NO];
            [self parseTypes:body];
            [self parseModels];
            mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", nil];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/getautomationconditions" withData:mapData isAsync:NO];
            globals.condtions = [self parseCondtions:body];
            mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", nil];
            body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/getactionperipheralcategories" withData:mapData isAsync:NO];
            globals.aPC = [self parseCategories:body];
            for(NSString *category in globals.aPC){
                mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", category, @"PeripheralCategoryName", nil];
                body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/getautomationactionsbyperipheralcategory" withData:mapData isAsync:NO];
                [globals.actions setObject:[self parseActions:body] forKey:category];
            }
            [self dismissViewControllerAnimated:TRUE completion:nil];
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
            [self dismissViewControllerAnimated:TRUE completion:nil];
            self.pass.backgroundColor = [UIColor redColor];
            self.user.backgroundColor = [UIColor redColor];
        }
    }];
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
                NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/register" withData:mapData isAsync:NO];
                if ([body containsString:@"Successfull inserted the user into the table"]){
                    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.userReg.text, @"username", [self sha256:self.regPass.text], @"password", nil];
                    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/login" withData:mapData isAsync:NO];
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
                        globals.houses = [[NSMutableArray alloc] init];
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

- (NSString *)post:(NSString *) link withData:(NSDictionary *) data isAsync:(BOOL)aSync{
    NSError *error;
    NSURL *url = [[NSURL alloc] initWithString:link];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json; charset=UTF8" forHTTPHeaderField:@"Content-Type"];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    request.HTTPBody = postData;
    if(aSync){
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *error){
            NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            self.returned = body;
        }];
        [task resume];
    }
    else{
        dispatch_semaphore_t sem;
        sem = dispatch_semaphore_create(0);
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *error){
            NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            self.returned = body;
            dispatch_semaphore_signal(sem);
        }];
        [task resume];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    return self.returned;
}

- (void)parseHouses:(NSString *)body{
    if ([body isEqualToString:@"[[]]"]){
        
    }
    else{
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
}

- (NSDictionary *)parseRelays:(NSString *)body{
    NSMutableDictionary *relays = [[NSMutableDictionary alloc] init];
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[[";
    NSString *haystackSuffix = @"]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@","];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        if (i % 2 == 0){
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"{\"PeripheralName\":\"";
            haystackSuffix = @"\"";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [keys addObject:[NSString stringWithString:needle]];
        }
        else{
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"\"PeripheralValue\":";
            haystackSuffix = @"}";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [relays setObject:needle forKey:keys[i/2]];
        }
    }
    return relays;
}
- (NSArray *)parseSensors:(NSString *)body{
    NSLog(@"%@", body);
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@"},{"] count] - 1;
    NSString *haystackPrefix = @"[[{";
    NSString *haystackSuffix = @"}]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@"},{"];
    NSMutableArray *sens = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSUInteger numberOfSens = [[houseArray[i] componentsSeparatedByString:@","] count];
        NSArray *senArray = [houseArray[i] componentsSeparatedByString:@","];
        for(int j = 0; j < numberOfSens; j++){
            if (j % 5 == 0){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"PeripheralName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 5 == 1){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"DisplayStyleName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 5 == 2){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"DisplayUnitsName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 5 == 3){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"PeripheralValue\":";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else{
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"PeripheralValueWithUnits\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
        }
        
    }
    return sens;
}
- (NSArray *)parseCameras:(NSString *)body{
    NSLog(@"%@", body);
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@"},{"] count] - 1;
    NSString *haystackPrefix = @"[[{";
    NSString *haystackSuffix = @"}]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@"},{"];
    NSMutableArray *sens = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSUInteger numberOfSens = [[houseArray[i] componentsSeparatedByString:@","] count];
        NSArray *senArray = [houseArray[i] componentsSeparatedByString:@","];
        for(int j = 0; j < numberOfSens; j++){
            if (j % 2 == 0){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"PeripheralName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 2 == 1){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"BoardName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
        }
        
    }
    return sens;
}
- (NSArray *)parseCondtions:(NSString *)body{
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@"},{"] count] - 1;
    NSString *haystackPrefix = @"[[{";
    NSString *haystackSuffix = @"}]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@"},{"];
    NSMutableArray *sens = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSString *house = (NSString *)houseArray[i];
        haystackPrefix = @"\"ActionCondition    Name\":\"";
        haystackSuffix = @"\"";
        needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
        needle = [house substringWithRange:needleRange];
        [sens addObject:[NSString stringWithString:needle]];
    }
    return sens;
}
- (NSArray *)parseCategories:(NSString *)body{
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@"},{"] count] - 1;
    NSString *haystackPrefix = @"[[{";
    NSString *haystackSuffix = @"}]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@"},{"];
    NSMutableArray *sens = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSString *house = (NSString *)houseArray[i];
        haystackPrefix = @"\"PeripheralCategoryName\":\"";
        haystackSuffix = @"\"";
        needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
        needle = [house substringWithRange:needleRange];
        [sens addObject:[NSString stringWithString:needle]];
    }
    return sens;
}
- (NSArray *)parseActions:(NSString *)body{
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@"},{"] count] - 1;
    NSString *haystackPrefix = @"[[{";
    NSString *haystackSuffix = @"}]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@"},{"];
    NSMutableArray *sens = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSString *house = (NSString *)houseArray[i];
        haystackPrefix = @"\"AutomationActionName\":\"";
        haystackSuffix = @"\"";
        needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
        needle = [house substringWithRange:needleRange];
        [sens addObject:[NSString stringWithString:needle]];
    }
    return sens;
}
- (NSArray *)parsePeripherals:(NSString *)body{
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[[";
    NSString *haystackSuffix = @"]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@","];
    NSMutableArray *peripherals = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        if (i % 4 == 0){
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"{\"PeripheralName\":\"";
            haystackSuffix = @"\"";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [peripherals addObject:[NSString stringWithString:needle]];
        }
        else if (i % 4 == 1){
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"\"BoardName\":\"";
            haystackSuffix = @"\"";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [peripherals addObject:[NSString stringWithString:needle]];
        }
        else if (i % 4 == 2){
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"\"PeripheralTypeName\":\"";
            haystackSuffix = @"\"";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [peripherals addObject:[NSString stringWithString:needle]];
        }
        else{
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"\"PeripheralCategoryName\":\"";
            haystackSuffix = @"\"}";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [peripherals addObject:[NSString stringWithString:needle]];
        }
    }
    return peripherals;
}

- (NSArray *)parseBoards:(NSString *)body{
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[[";
    NSString *haystackSuffix = @"]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@","];
    NSMutableArray *boards = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"{\"BoardName\":\"";
            haystackSuffix = @"\"}";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [boards addObject:[NSString stringWithString:needle]];
    }
    return boards;
}

- (NSDictionary *)getSensorData{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    for (NSString *house in globals.houses){
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: house, @"HouseName", globals.seshToke, @"SessionToken", nil];
        NSString *relayData = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/dev/relay/getrelayvaluesbyhouseid" withData:mapData  isAsync:NO];
        [data setValue:@"" forKey:house];
        NSMutableArray *periphData = [[NSMutableArray alloc] init];
        if ([relayData containsString:@"Peripheral"]){
            NSDictionary *relays = [self parseRelays:relayData];
            [periphData addObject:relays];
        }
        else{
            NSDictionary *relays = [[NSDictionary alloc] init];
            [periphData addObject:relays];
        }
        mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", house, @"houseName", nil];
        relayData = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/sensor/getsensorvaluesbyhouse" withData:mapData  isAsync:NO];
        NSArray *sensorData;
        if ([relayData containsString:@"Peripheral"]){
            sensorData = [self parseSensors:relayData];
        }
        else{
            sensorData = [[NSArray alloc] init];
        }
        [periphData addObject: sensorData];
        mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", house, @"houseName", nil];
        relayData = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/getcurrentcamerasbyhouse" withData:mapData isAsync:NO];
        NSArray *cameras;
        if ([relayData containsString:@"Peripheral"]){
            cameras = [self parseCameras:relayData];
        }
        else{
            cameras = [[NSArray alloc] init];
        }
        [periphData addObject:cameras];
        NSArray *actions;
        mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", house, @"houseName", nil];
        relayData = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/getcurrentrulesbyhouse" withData:mapData isAsync:NO];
        [periphData addObject:[self parseRules:relayData]];
        [data setObject:periphData forKey:house];
        NSLog(@"%@", data);
    }
    return data;
}
- (NSArray *)parseRules:(NSString *)body{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@"},{"] count] - 1;
    NSString *haystackPrefix = @"[[{";
    NSString *haystackSuffix = @"}]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@"},{"];
    NSMutableArray *sens = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSUInteger numberOfSens = [[houseArray[i] componentsSeparatedByString:@","] count];
        NSArray *senArray = [houseArray[i] componentsSeparatedByString:@","];
        for(int j = 0; j < numberOfSens; j++){
            if (j % 7 == 0){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"AutomationRuleName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 7 == 1){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"AutomationConditionPeripheralName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 7 == 2){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"AutomationConditionName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 7 == 3){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"AutomationConditionValue\":";
                haystackSuffix = @"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 7 == 4){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"AutomationActionPeripheralName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 7 == 5){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"AutomationActionName\":\"";
                haystackSuffix = @"\"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
            else if (j % 7 == 6){
                NSString *house = (NSString *)senArray[j];
                haystackPrefix = @"\"AutomationActionParameter\":";
                haystackSuffix = @"";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [sens addObject:[NSString stringWithString:needle]];
            }
        }
        
    }
    return sens;
}

- (void)parseTypes:(NSString *)body{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[[";
    NSString *haystackSuffix = @"]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@","];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSString *house = (NSString *)houseArray[i];
        haystackPrefix = @"{\"PeripheralTypeName\":\"";
        haystackSuffix = @"\"}";
        needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
        needle = [house substringWithRange:needleRange];
        [globals.peripheralTypes addObject:[NSString stringWithString:needle]];
    }
}

- (void)parseModels{
    GlobalVars *globals = [GlobalVars sharedInstance];
    for(int i = 0; i < [globals.peripheralTypes count]; i++){
        NSMutableArray *models = [[NSMutableArray alloc] init];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: [globals.peripheralTypes objectAtIndex:i], @"PeripheralTypeName", globals.seshToke, @"SessionToken", nil];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/getperipheralmodelsbyperipheraltype/" withData:mapData isAsync:NO];
        NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
        if ([body isEqualToString:@"[[]]"] || [body isEqualToString:@"{\"message\":null}"]){
            [globals.peripheralModels setObject:models forKey:[globals.peripheralTypes objectAtIndex:i]];
        }
        else{
            NSString *haystackPrefix = @"[[";
            NSString *haystackSuffix = @"]]";
            NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
            NSString *needle = [body substringWithRange:needleRange];
            NSArray *houseArray = [needle componentsSeparatedByString:@","];
            for(int i = 0; i < numberOfOccurrences + 1; i++){
                NSString *house = (NSString *)houseArray[i];
                haystackPrefix = @"{\"PeripheralTypeName\":\"\"";
                haystackSuffix = @"\"}";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [models addObject:[NSString stringWithString:needle]];
            }
            [globals.peripheralModels setObject:models forKey:[globals.peripheralTypes objectAtIndex:i]];
        }
    }
}

@end

