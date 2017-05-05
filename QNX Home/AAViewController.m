//
//  AAViewController.m
//  QNX Home
//
//  Created by Tyler Ford on 4/30/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import "AAViewController.h"
#import "GlobalVars.h"

@interface AAViewController ()

@end

@implementation AAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    GlobalVars *globals = [GlobalVars sharedInstance];
    self.cV.keyboardType = UIKeyboardTypeNumberPad;
    NSTimer *labelTimer = [NSTimer scheduledTimerWithTimeInterval: .25 target:self selector:@selector(refreshLabel) userInfo:nil repeats: NO];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    //One column
    
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    //set number of rows
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(pickerView == self.condition)
        return [globals.condtions count];
    if (pickerView == self.sensor){
        NSString *house = [globals.houses objectAtIndex:(globals.house - 2)];
        return [[globals.houseData objectForKey:house][1] count] / 5;
    }
    if(pickerView == self.actionPC)
        return [globals.aPC count];
    if(pickerView == self.actionP){
        NSString *house = [globals.houses objectAtIndex:(globals.house - 2)];
        if ([[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]] isEqualToString:@"Relay"])
            return [[globals.houseData objectForKey:house][0] count];
        else
            return [[globals.houseData objectForKey:house][2] count]/2;
    }
    if(pickerView == self.action)
        return [[globals.actions objectForKey:[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]]] count];
    return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    //set item per row
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(pickerView == self.condition)
        return globals.condtions[row];
    if (pickerView == self.sensor){
        NSString *house = [globals.houses objectAtIndex:globals.house - 2];
        return [[globals.houseData objectForKey:house][1] objectAtIndex:row * 5];
    }
    if(pickerView == self.actionPC)
        return globals.aPC[row];
    if(pickerView == self.actionP){
        NSString *house = [globals.houses objectAtIndex:(globals.house - 2)];
        if ([[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]] isEqualToString:@"Relay"])
            return [[[globals.houseData objectForKey:house][0] allKeys] objectAtIndex:row];
        else
            return [globals.houseData objectForKey:house][2][row];
    }
    if(pickerView == self.action)
        return [globals.actions objectForKey:[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]]][row];
    return @"Row Name";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if (pickerView == self.actionPC){
        [self.actionP reloadAllComponents];
        [self.action reloadAllComponents];
        [self refreshLabel];
    }
    if(pickerView == self.action){
        [self refreshLabel];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if (textField == self.rule){
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", [globals.houses objectAtIndex:(globals.house - 2)], @"houseName", self.rule.text, @"ruleName", nil];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/checkrulename" withData:mapData isAsync:NO];
        NSLog(@"%@", body);
        if([body containsString:@"1"])
            [self.rule setBackgroundColor:[UIColor greenColor]];
        else
            [self.rule setBackgroundColor:[UIColor redColor]];
    }
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
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

-(IBAction)add:(id)sender{
    if(self.rule.backgroundColor == [UIColor redColor]){
        UIAlertController *rule = [UIAlertController alertControllerWithTitle:@"Fix Title" message:@"Fix your rule title." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [rule addAction:ok];
        [self presentViewController:rule animated:YES completion:nil];
    }
    else{
        NSString *param;
        if ([self.aP.text isEqualToString:@""])
            param = @"1";
        else
             param = self.aP.text;
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSString *house = [globals.houses objectAtIndex:(globals.house - 2)];
        NSString *periph;
        if ([[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]] isEqualToString:@"Relay"])
            periph = [[[globals.houseData objectForKey:house][0] allKeys] objectAtIndex:[self.actionP selectedRowInComponent:0]];
        else
            periph = [globals.houseData objectForKey:house][2][[self.actionP selectedRowInComponent:0]];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", [globals.houses objectAtIndex:(globals.house - 2)], @"HouseName", self.rule.text, @"RuleName", [globals.houseData objectForKey:[globals.houses objectAtIndex:(globals.house - 2)]][1][[self.sensor selectedRowInComponent:0] * 5], @"ConditionPeripheralName", [globals.condtions objectAtIndex:[self.condition selectedRowInComponent:0]], @"AutomationConditionName", self.cV.text, @"AutomationConditionValue", periph, @"ActionPeripheralName", [globals.actions objectForKey:[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]]][[self.action selectedRowInComponent:0]], @"AutomationActionName", param, @"AutomationActionParameter", nil];
        UIAlertController *action = [UIAlertController alertControllerWithTitle:@"Adding Action" message:@"Adding action to your house." preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:action animated:YES completion:^(void){
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/createautomationrule" withData:mapData isAsync:NO];
            if ([body containsString:@"[]"]){
                NSMutableArray *actions = [globals.houseData objectForKey:house][3];
                [actions addObject:self.rule.text];
                [actions addObject:[globals.houseData objectForKey:[globals.houses objectAtIndex:(globals.house - 2)]][1][[self.sensor selectedRowInComponent:0] * 5]];
                [actions addObject:[globals.condtions objectAtIndex:[self.condition selectedRowInComponent:0]]];
                [actions addObject:self.cV.text];
                [actions addObject:periph];
                [actions addObject:[globals.actions objectForKey:[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]]][[self.action selectedRowInComponent:0]]];
                [actions addObject:self.aP.text];
                [[globals.houseData objectForKey:house] replaceObjectAtIndex:3 withObject:actions];
                [self dismissViewControllerAnimated:YES completion:^(void){
                    [self.navigationController popViewControllerAnimated:TRUE];
                }];
            }
            else{
                [self dismissViewControllerAnimated:YES completion:^(void){
                    UIAlertController *rule = [UIAlertController alertControllerWithTitle:@"Fix Options" message:@"Something went wrong, try changing options." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                    [rule addAction:ok];
                    [self presentViewController:rule animated:YES completion:nil];
                }];
            }
        }];
    }
}
-(IBAction)cancel:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)refreshLabel{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", [globals.actions objectForKey:[globals.aPC objectAtIndex:[self.actionPC selectedRowInComponent:0]]][[self.action selectedRowInComponent:0]], @"automationActionName", nil];
    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/getactionparameternames" withData:mapData isAsync:NO];
    NSString *haystackPrefix = @"[[{\"AutomationActionParameterDescription\":\"";
    NSString *haystackSuffix = @"\"}]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    self.desc.text = [NSString stringWithFormat:@"Parameter: %@", [body substringWithRange:needleRange]];
    if ([self.desc.text isEqualToString:@"Parameter: None"])
        [self.aP setEnabled:FALSE];
    else
        [self.aP setEnabled:TRUE];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
