//
//  ViewController.m
//  LGSideMenuControllerDemo
//

#include <CommonCrypto/CommonDigest.h>
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
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSMutableArray *words = globals.commands;
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
    picker = [[NSMutableArray alloc] initWithObjects:@"Choose a House", @"", nil];
    picker = [[picker arrayByAddingObjectsFromArray: globals.houses] mutableCopy];
    self.uname.text = globals.uname;
    [self.house selectRow:globals.house inComponent:0 animated:YES];
    if(globals.isConfig){
        if(globals.seg)
            [self.selector setSelectedSegmentIndex:1];
        else
            [self.selector setSelectedSegmentIndex:0];
    }
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    //One column
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    //set number of rows
    return picker.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    //set item per row
    return [picker objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    GlobalVars *globals = [GlobalVars sharedInstance];
    globals.house = row;
    if (!globals.isConfig && globals.type != 3 && globals.type != 4)
        [self transition:@"ViewController"];
    else if (globals.type == 3)
        [self transition:@"Camera"];
    else if (globals.type == 4)
        [self transition:@"Automation"];
    else
        [self transition:@"System"];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
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
    GlobalVars *globals = [GlobalVars sharedInstance];
    [self dismissViewControllerAnimated:TRUE completion:nil];
    [[OEPocketsphinxController sharedInstance] setActive:FALSE error:nil];
    [[OEPocketsphinxController sharedInstance] stopListening];
    NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    if ([hypothesis isEqualToString:@"Dashboard"] || [hypothesis isEqualToString:@"Sensors"] || [hypothesis isEqualToString:@"Relays"] || [hypothesis isEqualToString:@"Cameras"]){
        if ([hypothesis isEqualToString:@"Dashboard"])
            globals.type = 0;
        else if ([hypothesis isEqualToString:@"Sensors"])
            globals.type = 1;
        else if ([hypothesis isEqualToString:@"Relays"])
            globals.type = 2;
        else if ([hypothesis isEqualToString:@"Cameras"]){
            globals.type = 3;
            globals.isConfig = NO;
            [self transition:@"Camera"];
        }
        globals.isConfig = NO;
        [self transition:@"ViewController"];
    }
    else{
        UIAlertController *textConfirm = [UIAlertController alertControllerWithTitle:@"Confirm Command" message:hypothesis preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            NSArray *commandArray = [hypothesis componentsSeparatedByString:@" "];
            if ([hypothesis containsString:@" Show "]){
                NSString *periph = [[NSMutableString alloc] init];
                NSUInteger loc = [commandArray indexOfObject:@"Show"];
                NSMutableString *house = [[NSMutableString alloc] init];
                for(int h = 0; h < (int)loc; h++){
                    [house appendString:commandArray[h]];
                }
                NSDictionary *relays = [globals.houseData objectForKey:house][0];
                NSArray *sensors = [globals.houseData objectForKey:house][1];
                NSArray *cameras = [globals.houseData objectForKey:house][2];
                periph = commandArray[loc + 1];
                if ([[relays allKeys] containsObject:[NSString stringWithString:periph]] || [sensors containsObject:[NSString stringWithString:periph]]){
                    globals.type = 0;
                    globals.device = periph;
                    [self performSegueWithIdentifier:@"History" sender:self];
                }
                else if ([cameras containsObject:periph]){
                    globals.device = periph;
                    globals.type = 3;
                    [self performSegueWithIdentifier:@"History" sender:self];
                }
            }
            else if ([hypothesis containsString:@" Turn "]){
                NSMutableString *relay = [[NSMutableString alloc] init];
                NSUInteger loc = [commandArray indexOfObject:@"Turn"];
                NSMutableString *house = [[NSMutableString alloc] init];
                for(int h = 0; h < (int)loc; h++){
                    [house appendString:commandArray[h]];
                }
                NSDictionary *relays = [globals.houseData objectForKey:house][0];
                for(int i = (int)loc + 2; i < [commandArray count]; i++){
                    [relay appendString:commandArray[i]];
                }
                if ([commandArray[(int)loc + 1] isEqualToString:@"On"]){
                    [relays setValue:@"1" forKey:relay];
                }
                else{
                    [relays setValue:@"0" forKey:relay];
                }
                NSArray *data = [NSArray arrayWithObjects:relays, [globals.houseData objectForKey:house][1], nil];
                [globals.houseData setObject:data forKey:house];
                [self.tableView reloadData];
                NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", relay, @"PeripheralName", house, @"HouseName", [relays objectForKey:relay], @"PeripheralValue", nil];
                [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/dev/relay/setrelaystatus" withData:mapData isAsync:YES];
                if (globals.type < 3)
                    [self transition:@"ViewController"];
            }
            else{
                
            }
            
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
        [textConfirm addAction:confirm];
        [textConfirm addAction:cancel];
        [self presentViewController:textConfirm animated:YES completion:nil];
    }
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
            GlobalVars *globals = [GlobalVars sharedInstance];
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: [self sha256:self.pass.text], @"password", globals.seshToke, @"sessionToken", nil];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/changepassword" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"Changed Password Successfully"]){
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Password Changed" message:@"Successfully changed password." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [success addAction:ok];
                [self presentViewController:success animated:YES completion:nil];
            }
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
            GlobalVars *globals = [GlobalVars sharedInstance];
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.uNew.text, @"username", globals.seshToke, @"sessionToken", nil];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/changeusername" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"Changed Username Successfully"]){
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Username Changed" message:@"Username change password." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [success addAction:ok];
                [self presentViewController:success animated:YES completion:nil];
                globals.uname = self.uNew.text;
                self.uname.text = globals.uname;
            }
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
    else if(textField == self.hNew){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSLog(@"%@", mapData.allValues);
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability/" withData:mapData isAsync:NO];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"1"]){
            [self.hNew setBackgroundColor:[UIColor greenColor]];
        }
        else
            [self.hNew setBackgroundColor:[UIColor redColor]];
    }
    else if(textField == self.board){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSString *title = picker[globals.house];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: title, @"HouseName", globals.seshToke, @"SessionToken", self.board.text, @"BoardName", nil];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/checkboardnameavailability" withData:mapData isAsync:NO];
        if ([body containsString:@"1"])
            [self.board setBackgroundColor:[UIColor greenColor]];
        else
            [self.board setBackgroundColor:[UIColor redColor]];
    }
    else if(textField == self.chgH){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.chgH.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSLog(@"%@", mapData.allValues);
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability/" withData:mapData isAsync:TRUE];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"1"])
            [self.hNew setBackgroundColor:[UIColor redColor]];
        else
            [self.hNew setBackgroundColor:[UIColor greenColor]];
    }
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.pass)
        [self textFieldShouldReturn:textField];
    else if (textField == self.pass2)
        [self textFieldShouldReturn:textField];
    else if (textField == self.hNew)
        [self textFieldShouldReturn:textField];
}

- (IBAction)newHouse:(id)sender{
    UIAlertController *house = [UIAlertController alertControllerWithTitle:@"New House" message:@"Enter new house details." preferredStyle:UIAlertControllerStyleAlert];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"House Name";
        textField.delegate = self;
        self.hNew = textField;
    }];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"House Password";
        textField.delegate = self;
        textField.secureTextEntry = TRUE;
        self.pass = textField;
    }];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Add House" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        UIAlertController *adding = [UIAlertController alertControllerWithTitle:@"Adding House" message:@"Waiting for house to be added to your account." preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:adding animated:TRUE completion:nil];
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability/" withData:mapData isAsync:NO];
        NSString *hpass = [self sha256:self.pass.text];
        if ([body containsString:@"1"]){
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", hpass, @"housePassword", globals.seshToke, @"sessionToken", nil];
            NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/createhouse" withData:mapData isAsync:NO];
            if ([body containsString:@"Success"]){
                [globals.houses addObject:self.hNew.text];
                NSArray *boards = [[NSArray alloc] init];
                NSArray *periphs = [[NSArray alloc] init];
                [globals.allData setObject:[NSArray arrayWithObjects:periphs, boards, nil] forKey:self.hNew.text];
                [self dismissViewControllerAnimated:YES completion:nil];
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"House Added" message:@"Successfully created a new house." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [success addAction:ok];
                [self.houseList reloadData];
                [self presentViewController:success animated:TRUE completion:nil];
            }
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [house addAction:add];
    [house addAction:cancel];
    [self presentViewController:house animated:TRUE completion:nil];
}
- (IBAction)hName:(id)sender{
    UIAlertController *house = [UIAlertController alertControllerWithTitle:@"Change House Name" message:@"Enter new house name." preferredStyle:UIAlertControllerStyleAlert];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"House Password";
        textField.delegate = self;
        textField.secureTextEntry = TRUE;
        self.hpass = textField;
    }];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"New House Name";
        textField.delegate = self;
        self.uNew = textField;
    }];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Change Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.uNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSString *hpass = [self sha256:self.hpass.text];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability/" withData:mapData isAsync:NO];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"1"]){
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: [globals.houses objectAtIndex:self.selected], @"oldHouseName", hpass, @"housePassword", self.uNew.text, @"newHouseName", globals.seshToke, @"sessionToken", nil];
            body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/changehousename" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"Success"]){
                NSArray *data = [globals.houseData objectForKey:[globals.houses objectAtIndex:self.selected]];
                NSArray *all = [globals.allData objectForKey:[globals.houses objectAtIndex:self.selected]];
                [globals.houses removeObject:[globals.houses objectAtIndex:self.selected]];
                [globals.houses addObject:self.uNew.text];
                [globals.houseData removeObjectForKey:[globals.houses objectAtIndex:self.selected]];
                [globals.allData removeObjectForKey:[globals.houses objectAtIndex:self.selected]];
                [globals.houseData setObject:data forKey:self.uNew.text];
                [globals.allData setObject:data forKey:self.uNew.text];
                MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
                UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
                ViewController *viewController;
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
                
                viewController = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
                
                [navigationController setViewControllers:@[viewController]];
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Name Changed" message:@"Successfully changed house name." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [success addAction:ok];
                [self presentViewController:success animated:TRUE completion:nil];
            }
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [house addAction:add];
    [house addAction:cancel];
    [self presentViewController:house animated:TRUE completion:nil];
}

- (IBAction)hPass:(id)sender{
    UIAlertController *house = [UIAlertController alertControllerWithTitle:@"Change House Password" message:@"Enter new house password." preferredStyle:UIAlertControllerStyleAlert];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Old Password";
        textField.delegate = self;
        textField.secureTextEntry = TRUE;
        self.pass = textField;
    }];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"New Password";
        textField.delegate = self;
        textField.secureTextEntry = TRUE;
        self.temp = textField;
    }];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Change Password" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.uNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSString *hpass = [self sha256:self.pass.text];
        NSString *nhpass = [self sha256:self.temp.text];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability" withData:mapData isAsync:NO];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"0"]){
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: [globals.houses objectAtIndex:self.selected], @"houseName", hpass, @"oldHousePassword", nhpass, @"newHousePassword", globals.seshToke, @"sessionToken", nil];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/changehousepassword" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"Success"]){
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Password Changed" message:@"Successfully changed house password." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [success addAction:ok];
                [self presentViewController:success animated:TRUE completion:nil];
            }
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [house addAction:add];
    [house addAction:cancel];
    [self presentViewController:house animated:TRUE completion:nil];
}
- (IBAction)jHouse:(id)sender{
    UIAlertController *house = [UIAlertController alertControllerWithTitle:@"Join House" message:@"Join an existing house." preferredStyle:UIAlertControllerStyleAlert];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"House Name";
        textField.delegate = self;
        self.temp = textField;
    }];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"House Password";
        textField.delegate = self;
        textField.secureTextEntry = TRUE;
        self.uNew = textField;
    }];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Join House" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        UIAlertController *adding = [UIAlertController alertControllerWithTitle:@"Joining House" message:@"Waiting for house to be added to your account." preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:adding animated:TRUE completion:^(void){
            GlobalVars *globals = [GlobalVars sharedInstance];
            NSString *newHouse = self.temp.text;
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.temp.text, @"houseName", globals.seshToke, @"sessionToken", nil];
            NSString *hpass = [self sha256:self.uNew.text];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"0"]){
                NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.temp.text, @"houseName", hpass, @"housePassword", globals.seshToke, @"sessionToken", nil];
                NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/joinhouse" withData:mapData isAsync:NO];
                NSLog(@"Response Body:\n%@\n", body);
                if ([body containsString:@"Success"]){
                    [globals.houses addObject:self.temp.text];
                    [self dismissViewControllerAnimated:TRUE completion:^{
                        NSArray *array = [NSArray arrayWithObjects:[[NSDictionary alloc] init], [[NSArray alloc] init], [[NSArray alloc] init], [[NSArray alloc] init], nil];
                        [globals.houseData setObject:array forKey:self.temp.text];
                        UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Joined House" message:@"Successfully joined existing house." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                        [success addAction:ok];
                        [self presentViewController:success animated:TRUE completion:nil];
                        [self getSensorDataWithOption:@"All"];
                        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", newHouse, @"houseName", nil];
                        NSString *received = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/getcurrentperipheralsbyhouse" withData:mapData isAsync:NO];
                        NSArray *periphs;
                        if (![received isEqualToString:@"[[]]"] && ![received isEqualToString:@"{\"message\":null}"]){
                            periphs = (NSMutableArray *)[self parsePeripherals:received];
                        }
                        else{
                            periphs = [[NSMutableArray alloc] init];
                        }
                        mapData = [[NSDictionary alloc] initWithObjectsAndKeys: newHouse, @"HouseName", globals.seshToke, @"SessionToken", nil];
                        received = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/getboardsbyhouse" withData:mapData isAsync:NO];
                        NSMutableArray *boards;
                        if (![received isEqualToString:@"[[]]"] && ![received isEqualToString:@"{\"message\":null}"]){
                            boards = (NSMutableArray *)[self parseBoards:received];
                        }
                        else{
                            boards = [[NSMutableArray alloc] init];
                        }
                        [globals.allData setObject:[NSArray arrayWithObjects:periphs, boards, nil] forKey:newHouse];
                        [self.houseList reloadData];
                    }];
                }
                else{
                    [self dismissViewControllerAnimated:TRUE completion:nil];
                }
            }
            else{
                [self dismissViewControllerAnimated:TRUE completion:nil];
            }
        }];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [house addAction:add];
    [house addAction:cancel];
    [self presentViewController:house animated:TRUE completion:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    GlobalVars *globals = [GlobalVars sharedInstance];
    [self.system reloadData];
    [self.houseList reloadData];
    [self.cameras reloadData];
    [self.automation reloadData];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GlobalVars *globals = [GlobalVars sharedInstance];
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        //add a switch

    }
    if (tableView == self.automation){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        NSString *title = picker[globals.house];
        NSArray *actions = [globals.houseData objectForKey:title][3];
        cell.textLabel.text = actions[indexPath.row * 7];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ - %@", actions[indexPath.row * 7 + 1], actions[indexPath.row * 7 + 2], actions[indexPath.row * 7 + 3]];
        
    }
    else if(tableView == self.houseList){
        cell.textLabel.text = globals.houses[indexPath.row];
    }
    else if (tableView == self.system){
        NSString *title = picker[globals.house];
        NSArray *data = [globals.allData objectForKey:title];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        if([self.selector selectedSegmentIndex] == 0){
            NSArray *boards = data[1];
            cell.textLabel.text = boards[indexPath.row];
        }
        else{
            NSArray *periphs = data[0];
            cell.textLabel.text = periphs[indexPath.row * 4];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", periphs[indexPath.row * 4 + 2],periphs[indexPath.row * 4 + 1]];
        }
    }
    else if (globals.type == 2 || indexPath.section == 1){
        NSString *title = picker[[self.house selectedRowInComponent:0]];
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = switchView;
        NSArray *periphs = [globals.houseData objectForKey:title];
        NSDictionary *relays = periphs[0];
        NSString *text = [[globals.houseData objectForKey:title][0] allKeys][indexPath.row];
        if ([[relays objectForKey:text]  isEqual: @"0"])
            [switchView setOn:NO animated:YES];
        else
            [switchView setOn:YES animated:YES];
        [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        switchView.tag = indexPath.row;
        cell.textLabel.text = text;
        cell.detailTextLabel.text = nil;
    }
    else if(indexPath.section == 0 && ((globals.type == 0) || (globals.type == 1))){
        NSString *title = picker[globals.house];
        NSArray *sensors = [globals.houseData objectForKey:title][1];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", sensors[indexPath.row * 5]];
        cell.detailTextLabel.text = sensors[(indexPath.row * 5) + 4];
        cell.accessoryView = NULL;
    }
    else if (globals.type != 4){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        NSString *title = picker[globals.house];
        NSArray *cams = [globals.houseData objectForKey:title][2];
        cell.textLabel.text = cams[indexPath.row * 2];
        cell.detailTextLabel.text = cams[indexPath.row * 2 + 1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(tableView == self.houseList || tableView == self.system){
        return 1;
    }
    else {
        switch(globals.type){
            case 0:
                return 2;
            default:
                return 1;
        }
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(tableView == self.houseList){
        UIAlertController *houseOpts = [UIAlertController alertControllerWithTitle:@"House Options" message:[NSString stringWithFormat:@"%@ House Options", [globals.houses objectAtIndex:indexPath.row]] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *chgname = [UIAlertAction actionWithTitle:@"Change House Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self hName:self];
        }];
        UIAlertAction *chgpass = [UIAlertAction actionWithTitle:@"Change House Password" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self hPass:self];
        }];
        UIAlertAction *leave = [UIAlertAction actionWithTitle:@"Leave House" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", [globals.houses objectAtIndex:indexPath.row], @"houseName", nil];
            NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/leavehouse/" withData:mapData isAsync:NO];
            NSLog(@"%@", body);
            [globals.houses removeObjectAtIndex:indexPath.row];
            [self.houseList reloadData];
            MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
            UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
            ViewController *viewController;
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
            
            [navigationController setViewControllers:@[viewController]];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
        [houseOpts addAction:chgname];
        [houseOpts addAction:chgpass];
        [houseOpts addAction:leave];
        [houseOpts addAction:cancel];
        self.selected = indexPath.row;
        [self presentViewController:houseOpts animated:YES completion:nil];
    }
    else if (tableView == self.system){
        if ([self.selector selectedSegmentIndex] == 0){
            NSString *title = picker[globals.house];
            NSArray *data = [globals.allData objectForKey:title];
            NSArray *boards = data[1];
            UIAlertController *boardOpts = [UIAlertController alertControllerWithTitle:@"Board Options" message:[NSString stringWithFormat:@"%@ Board Options", [boards objectAtIndex:indexPath.row]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *chgname = [UIAlertAction actionWithTitle:@"Change Board Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                UIAlertController *house = [UIAlertController alertControllerWithTitle:@"Change Board Name" message:@"Enter the new board name." preferredStyle:UIAlertControllerStyleAlert];
                [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.placeholder = @"New Board Name";
                    textField.delegate = self;
                    self.board = textField;
                }];
                UIAlertAction *change = [UIAlertAction actionWithTitle:@"Change Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    GlobalVars *globals = [GlobalVars sharedInstance];
                    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", title, @"HouseName", [boards objectAtIndex:indexPath.row], @"OldBoardName", self.board.text, @"NewBoardName", nil];
                    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/changeboardname" withData:mapData isAsync:NO];
                    NSLog(@"Response Body:\n%@\n", body);
                    if ([body containsString:@"0 No Errors"]){
                        UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Changed Name" message:@"Successfully changed board name." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                        [success addAction:ok];
                        [self presentViewController:success animated:TRUE completion:nil];
                        NSArray *data = [globals.allData objectForKey:title];
                        NSMutableArray *boards = (NSMutableArray *)data[1];
                        [boards removeObject:[boards objectAtIndex:indexPath.row]];
                        [boards addObject:self.board.text];
                        [globals.allData setObject:[NSArray arrayWithObjects:data[0], boards, nil] forKey:title];
                        [tableView reloadData];
                        MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
                        UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
                        ViewController *viewController;
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
                            
                        viewController = [storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
                            
                        [navigationController setViewControllers:@[viewController]];
                    }
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
                [house addAction:change];
                [house addAction:cancel];
                [self presentViewController:house animated:TRUE completion:nil];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
            [boardOpts addAction:chgname];
            [boardOpts addAction:cancel];
            [self presentViewController:boardOpts animated:YES completion:nil];
        }
        else{
            NSString *title = picker[globals.house];
            NSArray *data = [globals.allData objectForKey:title];
            NSMutableArray *periphs = data[0];
            UIAlertController *boardOpts = [UIAlertController alertControllerWithTitle:@"Peripheral Options" message:[NSString stringWithFormat:@"%@ Peripheral Options", [periphs objectAtIndex:indexPath.row * 4]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *chgname = [UIAlertAction actionWithTitle:@"Change Peripheral Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                UIAlertController *house = [UIAlertController alertControllerWithTitle:@"Change Peripheral Name" message:@"Enter the new peripheral name." preferredStyle:UIAlertControllerStyleAlert];
                [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.placeholder = @"New Peripheral Name";
                    textField.delegate = self;
                    self.chgP = textField;
                }];
                UIAlertAction *change = [UIAlertAction actionWithTitle:@"Change Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    NSString *name = self.chgP.text;
                    GlobalVars *globals = [GlobalVars sharedInstance];
                    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", title, @"houseName", [periphs objectAtIndex:indexPath.row * 4], @"oldPeripheralName", self.chgP.text, @"newPeripheralName", nil];
                    NSLog(@"%@", mapData);
                    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/changeperipheralname/" withData:mapData isAsync:NO];
                    NSLog(@"Response Body:\n%@\n", body);
                    if ([body containsString:@"Successfully"]){
                        UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Changed Name" message:@"Successfully changed peripheral name." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                        [success addAction:ok];
                        [self presentViewController:success animated:TRUE completion:nil];
                        NSArray *data = [globals.allData objectForKey:title];
                        NSArray *boards = data[1];
                        [periphs addObject:name];
                        [periphs addObject:[periphs objectAtIndex:(indexPath.row * 4) + 1]];
                        [periphs addObject:[periphs objectAtIndex:(indexPath.row * 4) + 2]];
                        [periphs addObject:[periphs objectAtIndex:(indexPath.row * 4) + 3]];
                        [periphs removeObjectAtIndex:(indexPath.row * 4) + 3];
                        [periphs removeObjectAtIndex:(indexPath.row * 4) + 2];
                        [periphs removeObjectAtIndex:(indexPath.row * 4) + 1];
                        [periphs removeObjectAtIndex:indexPath.row * 4];
                        [globals.allData setObject:[NSArray arrayWithObjects:periphs, boards, nil] forKey:title];
                        [tableView reloadData];
                        NSLog(@"%@", periphs);
                        MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
                        UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
                        ViewController *viewController;
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
                        
                        viewController = [storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
                        
                        [navigationController setViewControllers:@[viewController]];
                    }
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
                [house addAction:change];
                [house addAction:cancel];
                [self presentViewController:house animated:TRUE completion:nil];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
            [boardOpts addAction:chgname];
            [boardOpts addAction:cancel];
            [self presentViewController:boardOpts animated:YES completion:nil];
        }
    }
    else if (tableView != self.automation){
        NSString *title = picker[globals.house];
        NSArray *data = [globals.houseData objectForKey:title];
        NSDictionary *relays = data[0];
        NSArray *sensors = data[1];
        NSArray *cameras = data[2];
        NSString *bar;
        if (indexPath.section == 1 || globals.type == 2){
            bar = [relays allKeys][indexPath.row];
        }
        else if(globals.type == 1 || (globals.type == 0 && indexPath.section == 0)){
            bar = sensors[(indexPath.row) * 5];
        }
        else{
            bar = cameras[(indexPath.row) * 2];
        }
        globals.device = bar;
        [self performSegueWithIdentifier:@"History" sender:self];
    }
    else if (tableView == self.automation){
        NSString *title = picker[globals.house];
        NSArray *actions = [globals.houseData objectForKey:title][3];
        NSString *message = [NSString stringWithFormat:@"If %@ is %@ %@, then %@ %@ %@", actions[(indexPath.row * 7) + 1], actions[(indexPath.row * 7) + 2], actions[(indexPath.row * 7) + 3], actions[(indexPath.row * 7) + 4], actions[(indexPath.row * 7) + 5], actions[(indexPath.row * 7) + 6]];
        UIAlertController *action = [UIAlertController alertControllerWithTitle:[actions objectAtIndex:indexPath.row * 7] message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [action addAction:ok];
        [self presentViewController:action animated:YES completion:nil];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(tableView == self.houseList){
        return [globals.houses count];
    }
    else if (tableView == self.system){
        NSString *title = picker[globals.house];
        NSArray *data = [globals.allData objectForKey:title];
        if([self.selector selectedSegmentIndex] == 0){
            NSArray *boards = data[1];
            return boards.count;
        }
        else{
            NSArray *boards = data[0];
            return boards.count / 4;
        }
    }
    else if (section == 1 || globals.type == 2){
        NSString *title = picker[globals.house];
        NSDictionary *relays = [globals.houseData objectForKey:title][0];
        if (relays == nil)
            return 0;
        return [relays count];
    }
    else if (section == 0 && (globals.type == 0 || globals.type == 1)){
        NSString *title = picker[globals.house];
        NSArray *sensors = [globals.houseData objectForKey:title][1];
        if (sensors == nil)
            return 0;
        return [sensors count] / 5;
    }
    else if (globals.type == 3){
        NSString *title = picker[globals.house];
        NSArray *cams = [globals.houseData objectForKey:title][2];
        if (cams == nil)
            return 0;
        return [cams count] / 2;
    }
    else if (tableView == self.automation){
        NSString *title = picker[globals.house];
        NSArray *actions = [globals.houseData objectForKey:title][3];
        if (actions == nil)
            return 0;
        return [actions count] / 7;
    }
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(tableView == self.houseList || tableView == self.system){
        return NULL;
    }
    switch(globals.type){
        case 0:
            if (section == 0)
                return @"Sensors";
            else
                return @"Relays";
        default:
            return NULL;
    }
    return NULL;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if(tableView == self.houseList || tableView == self.system || tableView == self.automation){
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    GlobalVars *globals = [GlobalVars sharedInstance];
    // Perform the real delete action here. Note: you may need to check editing style
    //   if you do not perform delete only.
    if(tableView == self.houseList){
        UIAlertController *deleteH = [UIAlertController alertControllerWithTitle:@"Delete House" message:[NSString stringWithFormat:@"Delete House: %@", [globals.houses objectAtIndex:indexPath.row]] preferredStyle:UIAlertControllerStyleAlert];
        [deleteH addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"House Password";
            textField.delegate = self;
            textField.secureTextEntry = TRUE;
            self.hpass = textField;
        }];
        UIAlertAction *leave = [UIAlertAction actionWithTitle:@"Leave House" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", [globals.houses objectAtIndex:indexPath.row], @"houseName", [self sha256:self.hpass.text], @"housePassword", nil];
            NSLog(@"%@", mapData);
            NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/removehouse/" withData:mapData isAsync:NO];
            NSLog(@"%@", body);
            NSLog(@"Deleted house: %@", globals.houses[indexPath.row]);
            NSString *house = [globals.houses objectAtIndex:indexPath.row];
            [globals.houses removeObject:house];
            MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
            UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
            ViewController *viewController;
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            
            viewController = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
            
            [navigationController setViewControllers:@[viewController]];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
        [deleteH addAction:leave];
        [deleteH addAction:cancel];
        self.selected = indexPath.row;
        [self presentViewController:deleteH animated:YES completion:nil];

    }
    else if (tableView == self.system){
        NSString *title = picker[globals.house];
        NSArray *data = [globals.allData objectForKey:title];
        if([self.selector selectedSegmentIndex] == 0){
            NSMutableArray *boards = data[1];
            NSLog(@"%@", boards);
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", title, @"HouseName", [NSString stringWithFormat:@"%@", boards[indexPath.row]], @"BoardName", nil];
            [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/removeboard" withData:mapData isAsync:YES];
            [boards removeObject:boards[indexPath.row]];
            NSArray *periphs = data[0];
            [globals.allData setObject:[NSArray arrayWithObjects:periphs, boards, nil] forKey:title];
            [tableView reloadData];
            NSLog(@"%@", boards);
        }
        else{
            NSMutableArray *boards = data[0];
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", title, @"houseName", boards[indexPath.row * 4], @"peripheralName", nil];
            NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/removeperipheral" withData:mapData isAsync:YES];
            NSMutableArray *houseData = [globals.houseData objectForKey:title];
            NSString *type = [globals.allData objectForKey:title][0][(indexPath.row * 4) + 3];
            if ([type isEqualToString:@"Sensor"]){
                NSMutableArray *sensors = houseData[1];
                NSUInteger ind = [sensors indexOfObject:boards[indexPath.row * 4]];
                [sensors removeObjectAtIndex:(ind + 4)];
                [sensors removeObjectAtIndex:(ind + 3)];
                [sensors removeObjectAtIndex:(ind + 2)];
                [sensors removeObjectAtIndex:(ind + 1)];
                [sensors removeObjectAtIndex:(ind)];
                if ([sensors count] == 0){
                    //[sensors addObject:@"Empty"];
                }
                [houseData replaceObjectAtIndex:1 withObject:sensors];
            }
            else if ([type isEqualToString:@"Relay"]){
                NSMutableDictionary *relays = houseData[0];
                [relays removeObjectForKey:boards[indexPath.row * 4]];
                if ([relays count] == 0){
                    //[relays setObject:@"1" forKey:@"Empty"];
                }
                [houseData replaceObjectAtIndex:0 withObject:relays];
            }
            else if ([type isEqualToString:@"Camera"]){
                NSMutableArray *cams = houseData[2];
                [cams removeObjectAtIndex:[cams indexOfObject:boards[indexPath.row * 4]] + 1];
                [cams removeObject:boards[indexPath.row * 4]];
            }
            [globals.houseData setObject:houseData forKey:title];
            [boards removeObjectAtIndex:(indexPath.row * 4) + 3];
            [boards removeObjectAtIndex:(indexPath.row * 4) + 2];
            [boards removeObjectAtIndex:(indexPath.row * 4) + 1];
            [boards removeObjectAtIndex:(indexPath.row * 4)];
            NSArray *periphs = data[1];
            [globals.allData setObject:[NSArray arrayWithObjects:boards, periphs, nil] forKey:title];
            [tableView reloadData];
        }
    }
    else if (tableView == self.automation){
        NSString *title = picker[globals.house];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", title, @"houseName", [globals.houseData objectForKey:title][3][indexPath.row * 7], @"ruleName", nil];
        [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/removeautomationrule" withData:mapData isAsync:YES];
        NSMutableArray *actions = [globals.houseData objectForKey:title][3];
        [actions removeObjectAtIndex:((indexPath.row * 7) + 6)];
        [actions removeObjectAtIndex:((indexPath.row * 7) + 5)];
        [actions removeObjectAtIndex:((indexPath.row * 7) + 4)];
        [actions removeObjectAtIndex:((indexPath.row * 7) + 3)];
        [actions removeObjectAtIndex:((indexPath.row * 7) + 2)];
        [actions removeObjectAtIndex:((indexPath.row * 7) + 1)];
        [actions removeObjectAtIndex:(indexPath.row * 7)];
        if ([actions count] == 0){
                //[sensors addObject:@"Empty"];
        }
        [[globals.houseData objectForKey:title] replaceObjectAtIndex:3 withObject:actions];
        [self.automation reloadData];
    }
}

-(void) switchChanged:(id) sender{
    NSInteger rowIndex = [sender tag];
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSString *houseN = picker[globals.house];
    NSDictionary *relays = [globals.houseData objectForKey:houseN][0];
    NSString *pName = [relays allKeys][rowIndex];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", pName, @"PeripheralName", houseN, @"HouseName", [NSString stringWithFormat:@"%d", [sender isOn]], @"PeripheralValue", nil];
    [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/dev/relay/setrelaystatus" withData:mapData isAsync:YES];
    if ([sender isOn])
        [relays setValue:@"1" forKey:pName];
    else
        [relays setValue:@"0" forKey:pName];
    NSMutableArray *house = [globals.houseData objectForKey:houseN];
    [globals.houseData setObject:house forKey:houseN];
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
-(IBAction)segChange:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if ([self.selector selectedSegmentIndex] == 0){
        MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
        UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
        ViewController *viewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"System"];
        
        [navigationController setViewControllers:@[viewController]];
        globals.seg = FALSE;
    }
    else{
        globals.seg = YES;
        MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
        UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
        ViewController *viewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"System"];
        
        [navigationController setViewControllers:@[viewController]];
    }
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

- (void)getSensorDataWithOption:(NSString *)option{
    GlobalVars *globals = [GlobalVars sharedInstance];
    BOOL go = TRUE;
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSArray *houses;
    if ([option isEqualToString:@"All"]){
        houses = globals.houses;
    }
    else{
        houses = [NSArray arrayWithObject:picker[globals.house]];
        go = NO;
    }
    for (NSString *house in globals.houses){
        NSDictionary *mapData;
        NSString *relayData;
        NSMutableArray *periphData = [[NSMutableArray alloc] init];
        if (go || [option isEqualToString:@"Dash"] || [option isEqualToString:@"Relays"]){
            mapData = [[NSDictionary alloc] initWithObjectsAndKeys: house, @"HouseName", globals.seshToke, @"SessionToken", nil];
            relayData = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/dev/relay/getrelayvaluesbyhouseid" withData:mapData  isAsync:NO];
            [data setValue:@"" forKey:house];
            NSDictionary *relays;
            if ([relayData containsString:@"Peripheral"]){
                relays = [self parseRelays:relayData];
            }
            else{
                relays = [[NSDictionary alloc] init];
            }
            NSArray *data = [NSArray arrayWithObjects:relays, [globals.houseData objectForKey:house][1], [globals.houseData objectForKey:house][2], [globals.houseData objectForKey:house][3], nil];
            [globals.houseData setObject:data forKey:house];
        }
        if (go || [option isEqualToString:@"Dash"] || [option isEqualToString:@"Sensors"]){
            mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", house, @"houseName", nil];
            relayData = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/sensor/getsensorvaluesbyhouse" withData:mapData  isAsync:NO];
            NSArray *sensorData;
            if ([relayData containsString:@"Peripheral"]){
                sensorData = [self parseSensors:relayData];
            }
            else{
                sensorData = [[NSArray alloc] init];
            }
            NSArray *data = [NSArray arrayWithObjects:[globals.houseData objectForKey:house][0], sensorData, [globals.houseData objectForKey:house][2], [globals.houseData objectForKey:house][3], nil];
            [globals.houseData setObject:data forKey:house];
        }
        if (go || [option isEqualToString:@"Cameras"]){
            mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", house, @"houseName", nil];
            relayData = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/getcurrentcamerasbyhouse" withData:mapData isAsync:NO];
            NSArray *cameras;
            if ([relayData containsString:@"Peripheral"]){
                cameras = [self parseCameras:relayData];
            }
            else{
                cameras = [[NSArray alloc] init];
            }
            NSArray *data = [NSArray arrayWithObjects:[globals.houseData objectForKey:house][0], [globals.houseData objectForKey:house][1], cameras, [globals.houseData objectForKey:house][3], nil];
            [globals.houseData setObject:data forKey:house];
        }
    }
}

- (NSDictionary *)parseRelays:(NSString *)body{
    NSMutableDictionary *relays = [[NSMutableDictionary alloc] init];
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[{";
    NSString *haystackSuffix = @"}]";
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
- (NSArray *)parsePeripherals:(NSString *)body{
    NSLog(@"%@", body);
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

-(IBAction)newBoard:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if ([globals.houses count] == 0 || globals.houses == nil){
        UIAlertController *house = [UIAlertController alertControllerWithTitle:@"No House" message:@"You must create or join a house before you can add a board." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [house addAction:ok];
        [self presentViewController:house animated:TRUE completion:nil];
    }
    else{
        UIAlertController *board = [UIAlertController alertControllerWithTitle:@"New Board" message:@"Register a new board." preferredStyle:UIAlertControllerStyleAlert];
        [board addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Board Serial #";
            textField.delegate = self;
            self.boardSer = textField;
        }];
        [board addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Board Name";
            textField.delegate = self;
            self.board = textField;
        }];
        UIAlertAction *add = [UIAlertAction actionWithTitle:@"Add Board" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            UIAlertController *adding = [UIAlertController alertControllerWithTitle:@"Adding Board" message:@"Waiting for board to be added to your account." preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:adding animated:TRUE completion:^{
                NSString *title = picker[globals.house];
                NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: title, @"HouseName", globals.seshToke, @"SessionToken", self.board.text, @"BoardName", nil];
                NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/checkboardnameavailability" withData:mapData isAsync:NO];
                NSLog(@"%@", body);
                if ([body containsString:@"1"]){
                    mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", self.boardSer.text, @"BoardSerialNumber", title, @"HouseName", self.board.text, @"BoardName", nil];
                    body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/createboard" withData:mapData isAsync:NO];
                    NSLog(@"Response Body:\n%@\n", body);
                    if ([body containsString:@"0"]){
                        [self dismissViewControllerAnimated:YES completion:^{
                            NSString *houseN = picker[globals.house];
                            UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Created Board" message:@"Successfully registered new board." preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                            [success addAction:ok];
                            [self presentViewController:success animated:TRUE completion:nil];
                            NSArray *data = [globals.allData objectForKey:houseN];
                            NSMutableArray *boards = [[NSMutableArray alloc] init];
                            [boards addObjectsFromArray:data[1]];
                            [boards addObject:self.board.text];
                            [globals.allData setObject:[NSArray arrayWithObjects:data[0], boards, nil] forKey:houseN];
                            [self.system reloadData];
                        }];
                    }
                }
            }];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
        [board addAction:add];
        [board addAction:cancel];
        [self presentViewController:board animated:TRUE completion:nil];
    }
}

-(IBAction)newP:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if ([globals.houses count] == 0 || globals.houses == nil){
        UIAlertController *house = [UIAlertController alertControllerWithTitle:@"No House" message:@"You must create or join a house before you can add a peripheral." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [house addAction:ok];
        [self presentViewController:house animated:TRUE completion:nil];
    }
    else{
        [self performSegueWithIdentifier:@"Peripheral" sender:self];
    }
}

-(void)transition:(NSString *)page{
    MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
    UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
    ViewController *viewController;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    
    viewController = [storyboard instantiateViewControllerWithIdentifier:page];
    
    [navigationController setViewControllers:@[viewController]];
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

-(IBAction)refresh:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    UIAlertController *refresh = [UIAlertController alertControllerWithTitle:@"Refreshing" message:@"Refreshing user data, please wait." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:refresh animated:YES completion:^(void){
        NSString *option;
        if (globals.type == 0){
            option = @"Dash";
        }
        else if (globals.type == 1){
            option = @"Sensors";
        }
        else{
            option = @"Relays";
        }
        [self getSensorDataWithOption:option];
        [self.tableView reloadData];
        [self dismissViewControllerAnimated:YES completion:^(void){
            [self transition:@"ViewController"];
        }];
    }];
    
}
-(IBAction)action:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if (globals.house == 0 || globals.house == 1){
        UIAlertController *house = [UIAlertController alertControllerWithTitle:@"Select House" message:@"You must select a house first." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [house addAction:ok];
        [self presentViewController:house animated:YES completion:nil];
    }
    else{
        [self performSegueWithIdentifier:@"Action" sender:self];
    }
    
}


@end
