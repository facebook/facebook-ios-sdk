//
//  MPAppDelegate.h
//  MyProfile
//
//  Created by Greg Schechter on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <FBiOSSDK/FacebookSDK.h>

@class MPViewController;

@interface MPAppDelegate : UIResponder<UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MPViewController *viewController;
@property (strong, nonatomic) FBSession *session;

@end
