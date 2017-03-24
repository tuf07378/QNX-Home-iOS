//
//  ViewController.m
//  LGSideMenuControllerDemo
//

#import "ViewController.h"
#import "LoginNavigationController.h"
#import "MainViewController.h"
#import "GlobalVars.h"
#import "UIViewController+LGSideMenuController.h"


@implementation ViewController

NSString *lmPath = nil;
NSString *dicPath = nil;
NSArray *picker;



- (void)viewDidLoad{
    OELanguageModelGenerator *lmGenerator = [[OELanguageModelGenerator alloc] init];
    
    NSArray *words = [NSArray arrayWithObjects:@"TURN", @"LIGHT", @"TURN ON", @"THE LIGHT", nil];
    NSString *name = @"NameIWantForMyLanguageModelFiles";
    NSError *err = [lmGenerator generateLanguageModelFromArray:words withFilesNamed:name forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to create a Spanish language model instead of an English one.
    

    
    if(err == nil) {
        
        lmPath = [lmGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"NameIWantForMyLanguageModelFiles"];
        dicPath = [lmGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"NameIWantForMyLanguageModelFiles"];
        
    } else {
        NSLog(@"Error: %@",[err localizedDescription]);
    }
    self.openEarsEventsObserver = [[OEEventsObserver alloc] init];
    [self.openEarsEventsObserver setDelegate:self];
    picker = [[NSArray alloc] initWithObjects:@"Choose a House", @"", @"Retired", @"Homemaker", @"Self-employed", @"Unemployed", @"Other", nil];
    GlobalVars *globals = [GlobalVars sharedInstance];
    self.uname.text = globals.uname;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    //One column
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //set number of rows
    return picker.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //set item per row
    return [picker objectAtIndex:row];
}

- (IBAction)voice:(id)sender{
        [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dicPath acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to perform Spanish recognition instead of English.
    UIAlertController *command = [UIAlertController alertControllerWithTitle:@"Input Command" message:@"Listening, please say a command." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
        [[OEPocketsphinxController sharedInstance] setActive:FALSE error:nil];
        [[OEPocketsphinxController sharedInstance] stopListening];
    }];
    [command addAction:cancel];
    [self presentViewController:command animated:YES completion:nil];
}
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    [self dismissViewControllerAnimated:TRUE completion:nil];
    [[OEPocketsphinxController sharedInstance] setActive:FALSE error:nil];
    [[OEPocketsphinxController sharedInstance] stopListening];
    NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    UIAlertController *textConfirm = [UIAlertController alertControllerWithTitle:@"Confirm Command" message:hypothesis preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [textConfirm addAction:confirm];
    [textConfirm addAction:cancel];
    [self presentViewController:textConfirm animated:YES completion:nil];
}

- (void) pocketsphinxDidStartListening {
    NSLog(@"Pocketsphinx is now listening.");
}

- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Pocketsphinx has detected speech.");
}

- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
}

- (void) pocketsphinxDidStopListening {
    NSLog(@"Pocketsphinx has stopped listening.");
}

- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Pocketsphinx has suspended recognition.");
}

- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Pocketsphinx has resumed recognition.");
}

- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
    NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

- (void) pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening setup wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void) pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening teardown wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void) testRecognitionCompleted {
    NSLog(@"A test file that was submitted for recognition is now complete.");
}
-(IBAction)changePW:(id)sender{
    UIAlertController *changePW = [UIAlertController alertControllerWithTitle:@"Change Password" message:@"Enter your desired password." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        if (self.pass.text != self.pass2.text){
            UIAlertController *noMatch = [UIAlertController alertControllerWithTitle:@"Non-Matching Passwords" message:@"Your passwords do not match." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil];
            [noMatch addAction:ok];
            [self presentViewController:noMatch animated:YES completion:nil];
        }
        else{
            NSError *error;
            
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
            NSURL *url = [NSURL URLWithString:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/changepassword"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                               timeoutInterval:60.0];
            
            [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
            
            [request setHTTPMethod:@"POST"];
            GlobalVars *globals = [GlobalVars sharedInstance];
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.pass.text, @"password", globals.seshToke, @"sessionToken", nil];
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
                if ([body containsString:@"Changed Password Successfully"]){
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Password Changed" message:@"Successfully change password." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                    [success addAction:ok];
                    [self presentViewController:success animated:YES completion:nil];
                }
            }];
            [postDataTask resume];
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [changePW addTextFieldWithConfigurationHandler:^(UITextField
                                                     *textField) {
        textField.placeholder = @"Password";
        textField.secureTextEntry = true;
        textField.delegate = self;
        self.pass = textField;
    }];
    [changePW addTextFieldWithConfigurationHandler:^(UITextField
                                                     *textField) {
        textField.placeholder = @"Password Confirmation";
        textField.secureTextEntry = true;
        textField.delegate = self;
        self.pass2 = textField;
    }];
    [changePW addAction:confirm];
    [changePW addAction:cancel];
    [self presentViewController:changePW animated:YES completion:nil];
    
}

- (IBAction)changeUname:(id)sender{
    UIAlertController *changeUname = [UIAlertController alertControllerWithTitle:@"Change Username" message:@"Enter your desired username." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        if ([self.uNew.text isEqual: @""]){
            [self.uNew setBackgroundColor:[UIColor redColor]];
        }
        else{
            NSError *error;
            
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
            NSURL *url = [NSURL URLWithString:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/changeusername"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                               timeoutInterval:60.0];
            
            [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
            
            [request setHTTPMethod:@"POST"];
            GlobalVars *globals = [GlobalVars sharedInstance];
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.uNew.text, @"username", globals.seshToke, @"sessionToken", nil];
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
                if ([body containsString:@"Changed Username Successfully"]){
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Username Changed" message:@"Username change password." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                    [success addAction:ok];
                    [self presentViewController:success animated:YES completion:nil];
                    globals.uname = self.uNew.text;
                    self.uname.text = globals.uname;
                }
            }];
            
            [postDataTask resume];
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [changeUname addTextFieldWithConfigurationHandler:^(UITextField
                                                     *textField) {
        textField.placeholder = @"Username";
        textField.delegate = self;
        self.uNew = textField;
    }];
    [changeUname addAction:confirm];
    [changeUname addAction:cancel];
    [self presentViewController:changeUname animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.pass2){
        if (self.pass2.text != self.pass.text){
            self.pass.backgroundColor = [UIColor redColor];
            self.pass2.backgroundColor = [UIColor redColor];
        }else{
            self.pass.backgroundColor = [UIColor greenColor];
            self.pass2.backgroundColor = [UIColor greenColor];
        }
    }
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.pass)
        [self textFieldShouldReturn:textField];
    else if (textField == self.pass2)
        [self textFieldShouldReturn:textField];
}

- (IBAction)newHouse:(id)sender{
    MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [sb instantiateViewControllerWithIdentifier:@"House"];
    UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
    [navigationController pushViewController:viewController animated:YES];
}

@end
