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

NSArray *types;
NSMutableArray *models;
NSMutableDictionary *boardModels;
NSMutableArray *pins;

@implementation APViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    GlobalVars *globals = [GlobalVars sharedInstance];
    if ([globals.houses count] == 0 || globals.houses == nil){
        [self.navigationController popViewControllerAnimated:YES];
    }
    types = globals.peripheralTypes;
    boardModels = globals.peripheralModels;
    models = [[NSMutableArray alloc] init];
    NSString *title = globals.houses[[self.house selectedRowInComponent:0]];
    NSArray *data = [globals.allData objectForKey:title];
    NSArray *boards = data[1];
    UIAlertController *newP = [UIAlertController alertControllerWithTitle:@"New Device" message:@"Please select location and peripheral data." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
    [newP addAction:ok];
    [self presentViewController:newP animated:YES completion:^{
        [self.house selectRow:0 inComponent:0 animated:YES];
        [self.board selectRow:0 inComponent:0 animated:YES];
        [self.pType selectRow:0 inComponent:0 animated:YES];
        [self.pMod selectRow:0 inComponent:0 animated:YES];
        [models addObjectsFromArray:[globals.peripheralModels objectForKey:globals.peripheralTypes[[self.pType selectedRowInComponent:0]]]];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: title, @"HouseName", globals.seshToke, @"SessionToken", boards[[self.board selectedRowInComponent:0]], @"BoardName", globals.peripheralTypes[[self.pType selectedRowInComponent:0]], @"PeripheralTypeName", nil];
        NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/getavailablepinconnections/" withData:mapData isAsync:NO];
        [self parsePins:body];
        [self.pCon reloadAllComponents];
        [self.pCon selectRow:0 inComponent:0 animated:YES];
    }];
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
        if ([pins[0] isEqualToString:@"Empty"]){
            return 0;
        }
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
    if (pickerView == self.house){
        [self.board reloadAllComponents];
        [self.pCon reloadAllComponents];
        [self.pMod reloadAllComponents];
    }
    else if(pickerView == self.pType){
        [models removeAllObjects];
        [models addObjectsFromArray:[globals.peripheralModels objectForKey:globals.peripheralTypes[row]]];
        NSLog(@"%@ %@ %@", types, models, boardModels);
        GlobalVars *globals = [GlobalVars sharedInstance];
        NSString *title = globals.houses[[self.house selectedRowInComponent:0]];
        NSArray *data = [globals.allData objectForKey:title];
        NSArray *boards = data[1];
        if (boards == nil || [boards count] == 0){
            UIAlertController *noBoard = [UIAlertController alertControllerWithTitle:@"No Board" message:@"You must add/select a board first." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
            [noBoard addAction:ok];
            [self presentViewController:noBoard animated:YES completion:nil];
        }
        else{
            NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: title, @"HouseName", globals.seshToke, @"SessionToken", boards[[self.board selectedRowInComponent:0]], @"BoardName", types[row], @"PeripheralTypeName", nil];
            NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/board/getavailablepinconnections/" withData:mapData isAsync:NO];
            [self parsePins:body];
            models = [boardModels objectForKey:types[[self.pType selectedRowInComponent:0]]];
            [self.pCon reloadAllComponents];
            [self.pMod reloadAllComponents];
        }
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
    NSString* body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/checkpheriperalnameavailability" withData:mapData isAsync:NO];
    NSLog(@"%@", body);
    if([body containsString:@"1"])
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

- (void)parsePins:(NSString *)body{
    pins = [[NSMutableArray alloc] init];
    if ([body isEqualToString:@"[[]]"]){
        pins = [NSMutableArray arrayWithObject:@"Empty"];
    }
    else{
        NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@","] count] - 1;
        NSString *haystackPrefix = @"[[";
        NSString *haystackSuffix = @"]]";
        NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
        NSString *needle = [body substringWithRange:needleRange];
        NSArray *houseArray = [needle componentsSeparatedByString:@","];
        for(int i = 0; i < numberOfOccurrences + 1; i++){
            NSString *house = (NSString *)houseArray[i];
            haystackPrefix = @"{\"PinConnectionName\":\"";
            haystackSuffix = @"\"}";
            needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
            needle = [house substringWithRange:needleRange];
            [pins addObject:[NSString stringWithString:needle]];
        }
    }
}
-(IBAction)addP:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSString *title = globals.houses[[self.house selectedRowInComponent:0]];
    NSArray *data = [globals.allData objectForKey:title];
    NSArray *boards = data[1];
    if (boards == nil || [boards count] == 0 || boards[[self.board selectedRowInComponent:0]] == nil){
        UIAlertController *noBoard = [UIAlertController alertControllerWithTitle:@"No Board" message:@"You must add a board first." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [noBoard addAction:ok];
        [self presentViewController:noBoard animated:YES completion:nil];
    }
    else{
        NSMutableArray *periphs = [[NSMutableArray alloc] init];
        [periphs addObjectsFromArray:data[0]];
        
        NSLog(@"%@ - %@", models[[self.pMod selectedRowInComponent:0]], pins[[self.pCon selectedRowInComponent:0]]);
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", title, @"houseName", boards[[self.board selectedRowInComponent:0]], @"boardName", self.pName.text, @"peripheralName", models[[self.pMod selectedRowInComponent:0]], @"peripheralModelName", pins[[self.pCon selectedRowInComponent:0]], @"pinConnectionName", nil];
        NSLog(@"%@", mapData);
        NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/peripheral/createperipheral/" withData:mapData isAsync:NO];
        NSLog(@"%@", body);
        if([body isEqualToString:@"[]"]){
            [self.navigationController popViewControllerAnimated:YES];
            [periphs addObject:self.pName.text];
            [periphs addObject:boards[[self.board selectedRowInComponent:0]]];
            [periphs addObject:models[[self.pMod selectedRowInComponent:0]]];
            NSString *type = types[[self.pType selectedRowInComponent:0]];
            if([type.lowercaseString containsString:@"sensor"]){
                [periphs addObject:@"Sensor"];
            }
            else if([type.lowercaseString containsString:@"relay"]){
                [periphs addObject:@"Relay"];
                NSMutableDictionary *newPeripheral = [globals.houseData objectForKey:title][0];
                [newPeripheral setObject:@"0" forKey:self.pName.text];
                NSMutableArray *data = [globals.houseData objectForKey:title];
                [data replaceObjectAtIndex:0 withObject:newPeripheral];
                [globals.houseData setObject:data forKey:title];
            }
            else{
                [periphs addObject:@"Camera"];
            }
        }
        [globals.allData setObject:[NSArray arrayWithObjects:periphs, boards, nil] forKey:title];
        
        
        NSLog(@"%@", globals.houseData);
    }
}

@end
