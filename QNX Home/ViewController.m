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
    
    NSArray *words = [NSArray arrayWithObjects:@"TURN", @"LIGHT", @"TURN ON", @"THE LIGHT", @"ON", nil];
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
    GlobalVars *globals = [GlobalVars sharedInstance];
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
    if (!globals.isConfig){
        MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
        UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
        ViewController *viewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        
        [navigationController setViewControllers:@[viewController]];
    }
    else{
        MainViewController *mainViewController = (MainViewController *)self.sideMenuController;
        UINavigationController *navigationController = (UINavigationController *)mainViewController.rootViewController;
        ViewController *viewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"System"];
        
        [navigationController setViewControllers:@[viewController]];
    }
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
    if(textField == self.hNew){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSLog(@"%@", mapData.allValues);
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability/" withData:mapData isAsync:TRUE];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"1"]){
            [self.hNew setBackgroundColor:[UIColor greenColor]];
        }
        else
            [self.hNew setBackgroundColor:[UIColor redColor]];
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
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability/" withData:mapData isAsync:NO];
        NSString *hpass = [self sha256:self.pass.text];
        if ([body containsString:@"1"]){
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", hpass, @"housePassword", globals.seshToke, @"sessionToken", nil];
            NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/createhouse" withData:mapData isAsync:NO];
            if ([body containsString:@"Success"]){
                [globals.houses addObject:self.hNew.text];
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"House Added" message:@"Successfully created a new house." preferredStyle:UIAlertControllerStyleAlert];
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
- (IBAction)hName:(id)sender{
    UIAlertController *house = [UIAlertController alertControllerWithTitle:@"Change House Name" message:@"Enter new house name." preferredStyle:UIAlertControllerStyleAlert];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Old House Name";
        textField.delegate = self;
        self.hNew = textField;
    }];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"House Password";
        textField.delegate = self;
        textField.secureTextEntry = TRUE;
        self.pass = textField;
    }];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"New House Name";
        textField.delegate = self;
        self.uNew = textField;
    }];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Change Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.uNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSString *hpass = [self sha256:self.pass.text];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability/" withData:mapData isAsync:NO];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"1"]){
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"oldHouseName", hpass, @"housePassword", self.uNew.text, @"newHouseName", globals.seshToke, @"sessionToken", nil];
            body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/changehousename" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"Success"]){
                [globals.houses addObject:self.pass.text];
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
        textField.placeholder = @"House Name";
        textField.delegate = self;
        self.uNew = textField;
    }];
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
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.uNew.text, @"houseName", hpass, @"oldHousePassword", nhpass, @"newHousePassword", globals.seshToke, @"sessionToken", nil];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/changehousepassword" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"Success"]){
                [globals.houses addObject:self.pass.text];
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
        self.hNew = textField;
    }];
    [house addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"House Password";
        textField.delegate = self;
        textField.secureTextEntry = TRUE;
        self.uNew = textField;
    }];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Join House" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", globals.seshToke, @"sessionToken", nil];
        NSString *hpass = [self sha256:self.uNew.text];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/check-house-availability" withData:mapData isAsync:NO];
        NSLog(@"Response Body:\n%@\n", body);
        if ([body containsString:@"0"]){
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: self.hNew.text, @"houseName", hpass, @"housePassword", globals.seshToke, @"sessionToken", nil];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/house/joinhouse" withData:mapData isAsync:NO];
            NSLog(@"Response Body:\n%@\n", body);
            if ([body containsString:@"Success"]){
                [globals.houses addObject:self.hNew.text];
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Joined House" message:@"Successfully joined existing house." preferredStyle:UIAlertControllerStyleAlert];
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

- (void)viewDidAppear:(BOOL)animated{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if (globals.type == 0){

    }
    else if (globals.type == 1){
        
    }
    else{
        
    }
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
    if(tableView == self.houseList){
        cell.textLabel.text = (NSString *)picker[indexPath.row + 2];
    }
    else if (tableView == self.system){
        NSString *title = picker[globals.house];
        NSArray *data = [globals.allData objectForKey:title];
        if([self.selector selectedSegmentIndex] == 0){
            NSArray *boards = data[1];
            cell.textLabel.text = boards[indexPath.row];
        }
        else{
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            NSArray *periphs = data[0];
            cell.textLabel.text = periphs[indexPath.row * 3];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", periphs[indexPath.row * 3 + 2],periphs[indexPath.row * 3 + 1]];
        }
    }
    else if (globals.type == 2 || indexPath.section == 1){
        NSString *title = picker[[self.house selectedRowInComponent:0]];
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = switchView;
        if ([[globals.houseData[title] allValues][indexPath.row]  isEqual: @"0"])
            [switchView setOn:NO animated:NO];
        else
            [switchView setOn:YES animated:NO];
        [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        switchView.tag = indexPath.row;
        cell.textLabel.text = [globals.houseData[title] allKeys][indexPath.row];
    }
    else if(indexPath.section == 0){
        cell.textLabel.text = [NSString stringWithFormat:@"Sensor Data %ld", indexPath.row + 1];
        cell.accessoryView = NULL;
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


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(tableView == self.houseList){
        return [picker count] - 2;
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
            return boards.count / 3;
        }
    }
    else if (section == 1 || globals.type == 2){
        NSString *title = picker[globals.house];
        if ([[globals.houseData[title] allKeys][0] isEqualToString:@"Empty"])
            return 0;
        return [globals.houseData[title] count];
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
    if(tableView == self.houseList){
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    GlobalVars *globals = [GlobalVars sharedInstance];
    // Perform the real delete action here. Note: you may need to check editing style
    //   if you do not perform delete only.
    NSLog(@"Deleted house: %@", globals.houses[indexPath.row]);
}

-(void) switchChanged:(id) sender{
    NSInteger rowIndex = [sender tag];
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSString *houseN = picker[globals.house];
    NSString *pName = [globals.houseData[houseN] allKeys][rowIndex];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", pName, @"PeripheralName", houseN, @"HouseName", [NSString stringWithFormat:@"%d", [sender isOn]], @"PeripheralValue", nil];
    [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/dev/relay/setrelaystatus" withData:mapData isAsync:YES];
    [globals.houseData[houseN] setObject:[NSString stringWithFormat:@"%d", [sender isOn]] forKey:pName];
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

@end
