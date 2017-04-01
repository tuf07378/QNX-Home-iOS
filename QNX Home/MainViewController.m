//
//  MainViewController.m
//  LGSideMenuControllerDemo
//

#import "MainViewController.h"
#import "ViewController.h"
#import "LeftViewController.h"
#import "RightViewController.h"

@interface MainViewController ()

@property (assign, nonatomic) NSUInteger type;

@end

@implementation MainViewController

- (void)setupWithType:(NSUInteger)type {
    self.type = type;

    // -----

    LeftViewController *leftViewController;
    RightViewController *rightViewController;

    if (self.storyboard) {
        leftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LeftViewController"];
        rightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RightViewController"];
        self.leftViewBackgroundColor = [UIColor colorWithRed:0.09 green:0.73 blue:1.0 alpha:0.9];
        // Sizes and styles is set in storybord
        // You can also find there all other parameters
        // LGSideMenuController fully customizable from storyboard
    }
    else {
        leftViewController = [LeftViewController new];
        rightViewController = [RightViewController new];

        self.leftViewWidth = 250.0;
        self.leftViewBackgroundColor = [UIColor colorWithRed:0.09 green:0.73 blue:1.0 alpha:0.9];
        self.rootViewCoverColorForLeftView = [UIColor colorWithRed:0.09 green:0.73 blue:1.0 alpha:0.05];

        self.rightViewWidth = 100.0;
        self.rightViewBackgroundColor = [UIColor colorWithRed:0.6 green:0.5 blue:0.6 alpha:0.9];
        self.rootViewCoverColorForRightView = [UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:0.05];
    }

    // -----

    UIBlurEffectStyle regularStyle;

    if (UIDevice.currentDevice.systemVersion.floatValue >= 10.0) {
        regularStyle = UIBlurEffectStyleRegular;
    }
    else {
        regularStyle = UIBlurEffectStyleLight;
    }

    // -----

    switch (type) {
        case 2: {
            self.leftViewPresentationStyle = LGSideMenuPresentationStyleSlideBelow;
            self.rightViewPresentationStyle = LGSideMenuPresentationStyleSlideBelow;

            break;
        }
    }

    // -----

    self.leftViewController = leftViewController;
    self.rightViewController = rightViewController;
}

- (void)leftViewWillLayoutSubviewsWithSize:(CGSize)size {
    [super leftViewWillLayoutSubviewsWithSize:size];

    if (!self.isLeftViewStatusBarHidden) {
        self.leftView.frame = CGRectMake(0.0, 20.0, size.width, size.height-20.0);
    }
}

- (void)rightViewWillLayoutSubviewsWithSize:(CGSize)size {
    [super rightViewWillLayoutSubviewsWithSize:size];

    if (!self.isRightViewStatusBarHidden ||
        (self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPadLandscape &&
         UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
         UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))) {
        self.rightView.frame = CGRectMake(0.0, 20.0, size.width, size.height-20.0);
    }
}

- (BOOL)isLeftViewStatusBarHidden {
    if (self.type == 8) {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    }

    return super.isLeftViewStatusBarHidden;
}

- (BOOL)isRightViewStatusBarHidden {
    if (self.type == 8) {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    }
    
    return super.isRightViewStatusBarHidden;
}

- (void)dealloc {
    NSLog(@"MainViewController deallocated");
}

@end
