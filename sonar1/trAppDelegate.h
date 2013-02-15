//
//  trAppDelegate.h
//  sonar1
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef trAppDelegateH
#define trAppDelegateH

#import <UIKit/UIKit.h>

@class trViewController;

@interface trAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) trViewController *viewController;

@end
#endif