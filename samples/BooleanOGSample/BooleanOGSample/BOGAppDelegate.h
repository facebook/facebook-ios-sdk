//
//  BOGAppDelegate.h
//  BooleanOGSample
//
//  Created by Jason Clark on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBiOSSDK/FacebookSDK.h>

@interface BOGAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

@property (strong, nonatomic) FBSession* session;

@end
