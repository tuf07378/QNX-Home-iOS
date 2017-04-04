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

@end
