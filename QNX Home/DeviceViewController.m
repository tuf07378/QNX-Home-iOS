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
        [self.start setHidden:YES];
        [self.end setHidden:YES];
    }
    else{
        [self loadImage];
        NSTimer *imageTimer = [NSTimer scheduledTimerWithTimeInterval: .25 target:self selector:@selector(loadImage) userInfo:nil repeats: YES];
    }
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)loadImage{
    NSString *ImageURL = @"https://s3.amazonaws.com/smart-home-gateway/test5.jpeg";
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:ImageURL]];
    self.imageView.image = [UIImage imageWithData:imageData];
    [self.imageView setClipsToBounds:YES];
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
-(IBAction)capture:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", @"HardwickCameraOne", @"peripheralName", @"Hardwick", @"houseName", nil];
    //NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", globals.device, @"peripheralName", [globals.houses objectAtIndex:globals.house-2], @"houseName", nil];
    [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/takepicture" withData:mapData isAsync:YES];
}
-(IBAction)setCameraFeedWithFPS:(id)sender{
    GlobalVars *globals = [GlobalVars sharedInstance];
    int isOn;
    int fps;
    if (sender == self.start)
        isOn = 1;
    else
        isOn = 0;
    fps = 2;
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", @"HardwickCameraOne", @"peripheralName", @"Hardwick", @"houseName", [NSString stringWithFormat:@"%d",isOn], @"cameraFeedValue", [NSString stringWithFormat:@"%d",fps], @"cameraFeedFPS", nil];
    //NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", globals.device, @"peripheralName", [globals.houses objectAtIndex:globals.house-2], @"houseName", nil];
    NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/setcamerafeed" withData:mapData isAsync:YES];
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
