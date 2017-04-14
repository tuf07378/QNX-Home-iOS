//
//  APViewController.m
//  QNX Home
//
//  Created by Tyler Ford on 4/13/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import "APViewController.h"
#import "GlobalVars.h"
#import "MainViewController.h"
#import "UIViewController+LGSideMenuController.h"

@interface APViewController ()

@end

NSMutableArray *types;
NSMutableArray *models;
NSMutableDictionary *boardModels;
NSMutableArray *pins;

@implementation APViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", nil];
    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/getperipheraltypes/" withData:mapData isAsync:NO];
    [self parseTypes:body];
    [self parseModels];
    NSString *title = globals.houses[[self.house selectedRowInComponent:0]];
    NSArray *data = [globals.allData objectForKey:title];
    NSArray *boards = data[1];
    mapData = [[NSDictionary alloc] initWithObjectsAndKeys: title, @"HouseName", globals.seshToke, @"SessionToken", boards[[self.board selectedRowInComponent:0]], @"BoardName", types[[self.pType selectedRowInComponent:0]], @"PeripheralTypeName", nil];
    body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/getavailablepinconnections/" withData:mapData isAsync:NO];
    [self parsePins:body];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)cancel:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    //One column

    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    //set number of rows
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(pickerView == self.house){
        return [globals.houses count];
    }
    else if (pickerView == self.board){
        NSArray *data = [globals.allData objectForKey:globals.houses[[self.house selectedRowInComponent:0]]];
        NSArray *boards = data[1];
        return [boards count];
    }
    else if (pickerView == self.pType){
        return [types count];
    }
    else if (pickerView == self.pMod){
        
        NSArray *mods = [boardModels objectForKey:[types objectAtIndex:[self.pType selectedRowInComponent:0]]];
        if ([mods count] == 0 || mods == nil){
            return 0;
        }
        return [mods count];
    }
    else if (pickerView == self.pCon){
        return [pins count];
    }
    return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    //set item per row
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(pickerView == self.house){
        return globals.houses[row];
    }
    else if (pickerView == self.board){
        NSArray *data = [globals.allData objectForKey:globals.houses[[self.house selectedRowInComponent:0]]];
        NSArray *boards = data[1];
        return [boards objectAtIndex:row];
    }
    else if (pickerView == self.pType){
        return [types objectAtIndex:row];
    }
    else if (pickerView == self.pMod){
        NSArray *mods = [boardModels objectForKey:[types objectAtIndex:[self.pType selectedRowInComponent:0]]];
        if(mods == nil || [mods count] == 0){
            
        }
        else
            return [mods objectAtIndex:row];
    }
    else if (pickerView == self.pCon){
        return [pins objectAtIndex:row];
    }
    return @"Row Name";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if(pickerView == self.pType){
        NSLog(@"%@ %@ %@", types, models, boardModels);
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSString *title = globals.houses[[self.house selectedRowInComponent:0]];
        NSArray *data = [globals.allData objectForKey:title];
        NSArray *boards = data[1];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: title, @"HouseName", globals.seshToke, @"SessionToken", boards[[self.board selectedRowInComponent:0]], @"BoardName", types[row], @"PeripheralTypeName", nil];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/getavailablepinconnections/" withData:mapData isAsync:NO];
        [self parsePins:body];
        models = [boardModels objectForKey:types[[self.pType selectedRowInComponent:0]]];
        [self.pCon reloadAllComponents];
        [self.pMod reloadAllComponents];
    }
    if(pickerView == self.pMod){
        
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSString *title = globals.houses[[self.house selectedRowInComponent:0]];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", title, @"houseName", self.pName.text, @"peripheralName", nil];
    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/checkperipheralnameavailability/" withData:mapData isAsync:NO];
    NSLog(@"%@", body);
    if([body containsString:@"0"])
        [self.pName setBackgroundColor:[UIColor greenColor]];
    else
        [self.pName setBackgroundColor:[UIColor redColor]];
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)parseTypes:(NSString *)body{
    types = [[NSMutableArray alloc] init];
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[[";
    NSString *haystackSuffix = @"]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@","];
    NSMutableArray *peripherals = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
        NSString *house = (NSString *)houseArray[i];
        haystackPrefix = @"{\"PeripheralTypeName\":\"";
        haystackSuffix = @"\"}";
        needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
        needle = [house substringWithRange:needleRange];
        [types addObject:[NSString stringWithString:needle]];
    }
}
- (void)parseModels{
    GlobalVars *globals = [GlobalVars sharedInstance];
    boardModels = [[NSMutableDictionary alloc] init];
    for(int i = 0; i < [types count]; i++){
        models = [[NSMutableArray alloc] init];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: [types objectAtIndex:i], @"PeripheralTypeName", globals.seshToke, @"SessionToken", nil];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/getperipheralmodelsbyperipheraltype/" withData:mapData isAsync:NO];
        NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
        if ([body isEqualToString:@"[[]]"] || [body isEqualToString:@"{\"message\":null}"]){
            [boardModels setObject:models forKey:[types objectAtIndex:i]];
        }
        else{
            NSString *haystackPrefix = @"[[";
            NSString *haystackSuffix = @"]]";
            NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
            NSString *needle = [body substringWithRange:needleRange];
            NSArray *houseArray = [needle componentsSeparatedByString:@","];
            NSMutableArray *peripherals = [[NSMutableArray alloc] init];
            for(int i = 0; i < numberOfOccurrences + 1; i++){
                NSString *house = (NSString *)houseArray[i];
                haystackPrefix = @"{\"PeripheralTypeName\":\"\"";
                haystackSuffix = @"\"}";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [models addObject:[NSString stringWithString:needle]];
            }
            [boardModels setObject:models forKey:[types objectAtIndex:i]];
        }
    }
}
- (void)parsePins:(NSString *)body{
    pins = [[NSMutableArray alloc] init];
    NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
    NSString *haystackPrefix = @"[[";
    NSString *haystackSuffix = @"]]";
    NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
    NSString *needle = [body substringWithRange:needleRange];
    NSArray *houseArray = [needle componentsSeparatedByString:@","];
    NSMutableArray *peripherals = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfOccurrences + 1; i++){
                NSString *house = (NSString *)houseArray[i];
                haystackPrefix = @"{\"PinConnectionName\":\"";
                haystackSuffix = @"\"}";
                needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                needle = [house substringWithRange:needleRange];
                [pins addObject:[NSString stringWithString:needle]];
    }
}
-(IBAction)addP:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSString *title = globals.houses[[self.house selectedRowInComponent:0]];
    NSArray *data = [globals.allData objectForKey:title];
    NSArray *boards = data[1];
    NSMutableArray *periphs = data[0];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", title, @"houseName", boards[[self.board selectedRowInComponent:0]], @"boardName", self.pName.text, @"peripheralName", models[[self.pMod selectedRowInComponent:0]], @"peripheralModelName", pins[[self.pCon selectedRowInComponent:0]], @"pinConnectionName", nil];
    NSLog(@"%@", mapData);
    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/createperipheral/" withData:mapData isAsync:NO];
    NSLog(@"%@", body);
    if([body isEqualToString:@"[]"]){
        UIAlertController *success = [UIAlertController alertControllerWithTitle:@"Device Added" message:@"Successfully added device." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [success addAction:ok];
        [self presentViewController:success animated:YES completion:nil];
        [periphs addObject:self.pName.text];
        [periphs addObject:boards[[self.board selectedRowInComponent:0]]];
        [periphs addObject:models[[self.pMod selectedRowInComponent:0]]];
        [periphs addObject:@"Sensor"];
    }
    [globals.allData setObject:[NSArray arrayWithObjects:periphs, boards, nil] forKey:title];
    NSLog(@"%@", globals.allData);
}
@end
