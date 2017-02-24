//
//  AppDelegate.h
//  QNX Home
//
//  Created by Tyler Ford on 2/24/17.
//  Copyright © 2017 Tyler Ford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

