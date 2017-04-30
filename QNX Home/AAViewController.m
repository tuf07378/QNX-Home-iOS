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
    return @"Row Name";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    GlobalVars *globals = [GlobalVars sharedInstance];
    if (pickerView == self.actionPC)
        [self.actionP reloadAllComponents];
    
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
    
}
-(IBAction)cancel:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
