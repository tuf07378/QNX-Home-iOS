//
//  DeviceViewController.m
//  QNX Home
//
//  Created by Tyler Ford on 4/22/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import "DeviceViewController.h"
#import "GlobalVars.h"
#import "BEMSimpleLineGraphView.h"
#import <QuartzCore/QuartzCore.h>

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
        [self.imageView setHidden:YES];
        NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"SessionToken", [globals.houses objectAtIndex:globals.house-2], @"HouseName", globals.device, @"PeripheralName", nil];
        //NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: globals.seshToke, @"sessionToken", globals.device, @"peripheralName", [globals.houses objectAtIndex:globals.house-2], @"houseName", nil];
        NSString *body = [self post:@"https://zvgalu45ka.execute-api.us-east-1.amazonaws.com/prod/gethistoricdata" withData:mapData isAsync:NO];
        self.data = [self parseHistorical:body];
        self.graph.averageLine.enableAverageLine = YES;
        self.graph.averageLine.alpha = 0.6;
        self.graph.averageLine.color = [UIColor darkGrayColor];
        self.graph.averageLine.width = 2.5;
        self.graph.averageLine.dashPattern = @[@(2),@(2)];
        self.graph.averageLine.title = @"Avg";
        self.graph.enableTouchReport = YES;
        self.graph.enablePopUpReport = YES;
        self.graph.autoScaleYAxis = YES;
        // self.myGraph.alwaysDisplayDots = YES;
        // self.myGraph.alwaysDisplayPopUpLabels = YES;
        self.graph.enableReferenceXAxisLines = YES;
        self.graph.enableReferenceYAxisLines = YES;
        self.graph.enableReferenceAxisFrame = YES;
        // Dash the y reference lines
        self.graph.lineDashPatternForReferenceYAxisLines = @[@(2),@(2)];
        self.graph.enableXAxisLabel = YES;
        // Show the y axis values with this format string
        self.graph.formatStringForValues = @"%.1f";
        
        // Setup initial curve selection segment
        self.curveChoice.selectedSegmentIndex = self.graph.enableBezierCurve;
        self.graph.layer.cornerRadius = 5;
        self.graph.layer.masksToBounds = YES;
        }
    else{
        [self loadImage];
        [self.graph setHidden:YES];
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

- (NSDictionary *)parseHistorical:(NSString *)body{
    NSLog(@"%@", body);
    if (body == nil || [body length] == 0 || [body isEqualToString:@"[[]]"]){
        return [NSDictionary dictionaryWithObject:@"1" forKey:@"Empty"];
    }
    else{
        NSUInteger numberOfOccurrences = [[body componentsSeparatedByString:@"},{"] count] - 1;
        NSString *haystackPrefix = @"[[{";
        NSString *haystackSuffix = @"}]]";
        NSRange needleRange = NSMakeRange(haystackPrefix.length, body.length - haystackPrefix.length - haystackSuffix.length);
        NSString *needle = [body substringWithRange:needleRange];
        NSArray *houseArray = [needle componentsSeparatedByString:@"},{"];
        NSMutableDictionary *sens = [[NSMutableDictionary alloc] init];
        NSString *time;
        for(int i = 0; i < numberOfOccurrences + 1; i++){
            NSUInteger numberOfSens = [[houseArray[i] componentsSeparatedByString:@","] count];
            NSArray *senArray = [houseArray[i] componentsSeparatedByString:@","];
            for(int j = 0; j < numberOfSens; j++){
                if (j % 2 == 0){
                    NSString *house = (NSString *)senArray[j];
                    haystackPrefix = @"\"Timestamp\":\"";
                    haystackSuffix = @"\"";
                    needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                    needle = [house substringWithRange:needleRange];
                    time = [NSString stringWithString:needle];
                }
                else if (j % 2 == 1){
                    NSString *house = (NSString *)senArray[j];
                    haystackPrefix = @"\"PeripheralValue\":";
                    haystackSuffix = @"";
                    needleRange = NSMakeRange(haystackPrefix.length, house.length - haystackPrefix.length - haystackSuffix.length);
                    needle = [house substringWithRange:needleRange];
                    [sens setObject:[NSString stringWithString:needle] forKey:time];
                }
            }
            
        }
        return sens;
    }
}

- (NSUInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    return [self.data count]; // Number of points in the graph.
}
- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSUInteger)index {
    return [[[self.data allValues] objectAtIndex:index] floatValue];
    // The value of the point on the Y-Axis for the index.
}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSUInteger)index {
    
    NSString *label = [[self.data allKeys] objectAtIndex:index];
    return [label stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
}

- (NSUInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph {
    return [self.data count]/5;
}
- (NSString *)popUpSuffixForlineGraph:(BEMSimpleLineGraphView *)graph {
    return @"°";
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
