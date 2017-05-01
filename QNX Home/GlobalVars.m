//
//  GlobalVars.m
//  QNX Home
//
//  Created by Tyler Ford on 3/23/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import "GlobalVars.h"

@implementation GlobalVars

+ (GlobalVars *)sharedInstance {
    static dispatch_once_t onceToken;
    static GlobalVars *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[GlobalVars alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _seshToke = nil;
        _uname = nil;
        _type = 0;
        _houses = [[NSMutableArray alloc] init];
        _houseData = [[NSMutableDictionary alloc] init];
        _house = 0;
        _isConfig = NO;
        _allData = [[NSMutableDictionary alloc] init];
        _seg = NO;
        _peripheralTypes = [[NSMutableArray alloc] init];
        _peripheralModels = [[NSMutableDictionary alloc] init];
        _commands = [[NSMutableArray alloc] init];
        _device = nil;
        _actions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

@end
