//
//  AAViewController.h
//  QNX Home
//
//  Created by Tyler Ford on 4/30/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AAViewController : UIViewController

@property IBOutlet UITextField *rule;
@property IBOutlet UIPickerView *sensor;
@property IBOutlet UIPickerView *condition;
@property IBOutlet UITextField *cV;
@property IBOutlet UIPickerView *actionPC;
@property IBOutlet UIPickerView *actionP;
@property IBOutlet UIPickerView *action;
@property IBOutlet UILabel *desc;
@property IBOutlet UITextField *aP;
@property (retain, readwrite) NSString *returned;


@end

