//
//  DeviceViewController.h
//  QNX Home
//
//  Created by Tyler Ford on 4/22/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceViewController : UIViewController

@property (retain, readwrite) IBOutlet UIImageView *imageView;
@property IBOutlet UIButton *capture;
@property (retain, readwrite) NSString *returned;

@end
