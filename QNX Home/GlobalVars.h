//
//  GlobalVars.h
//  QNX Home
//
//  Created by Tyler Ford on 3/23/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalVars : NSObject{
    NSString *_seshToke;
    NSString *_uname;
    NSInteger _type;
}

+ (GlobalVars *)sharedInstance;

@property(strong, nonatomic, readwrite) NSString *seshToke;
@property(strong, nonatomic, readwrite) NSString *uname;
@property(assign, nonatomic, readwrite) NSInteger type;
@property(retain, nonatomic, readwrite) NSMutableArray<NSString *> *houses;
@property(retain, nonatomic, readwrite) NSMutableDictionary *houseData;
@property(assign, nonatomic, readwrite) NSInteger house;
@property(assign, readwrite) BOOL isConfig;
@property(retain, nonatomic, readwrite) NSMutableDictionary *allData;
@property(assign, readwrite) BOOL seg;
@property(strong, nonatomic, readwrite) NSMutableArray *peripheralTypes;
@property(strong, nonatomic, readwrite) NSMutableDictionary *peripheralModels;
@property(strong, nonatomic, readwrite) NSMutableArray *commands;
@property(strong, nonatomic, readwrite) NSString *device;



@end
