//
//  DeviceViewController.m
//  QNX Home
//
//  Created by Tyler Ford on 4/22/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import "DeviceViewController.h"
#import "GlobalVars.h"

@interface DeviceViewController ()

@end

@implementation DeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    GlobalVars *globals = [GlobalVars sharedInstance];
    self.navigationItem.title = globals.device;
    if(globals.type != 3){
        [self.capture setHidden:YES];
    }
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

@end
