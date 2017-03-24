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
    }
    return self;
}

@end
