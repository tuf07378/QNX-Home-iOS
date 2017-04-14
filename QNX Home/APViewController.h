//
//  APViewController.h
//  QNX Home
//
//  Created by Tyler Ford on 4/13/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APViewController : UIViewController

@property (retain, readwrite) IBOutlet UITextField *pName;
@property (retain) IBOutlet UIPickerView *house;
@property (retain) IBOutlet UIPickerView *board;
@property (retain) IBOutlet UIPickerView *pType;
@property (retain) IBOutlet UIPickerView *pMod;
@property (retain) IBOutlet UIPickerView *pCon;
@property (retain, readwrite) NSString *returned;

@end
