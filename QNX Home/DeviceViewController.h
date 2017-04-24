//
//  DeviceViewController.h
//  QNX Home
//
//  Created by Tyler Ford on 4/22/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BEMSimpleLineGraphView.h"

@interface DeviceViewController : UIViewController <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>

@property (retain, readwrite) IBOutlet UIImageView *imageView;
@property IBOutlet UIButton *capture;
@property (retain, readwrite) NSString *returned;
@property IBOutlet UIButton *start;
@property IBOutlet UIButton *end;
@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *graph;
@property (readwrite, retain) NSDictionary *data;
@property (strong, nonatomic) IBOutlet UISegmentedControl *curveChoice;



@end
