//
//  JRAppDelegate.h
//  JustRequestSample
//
//  Created by Michael Marucheck on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JRViewController;

@interface JRAppDelegate : UIResponder <UIApplicationDelegate>

@property (retain, nonatomic) UIWindow *window;
@property (retain, nonatomic) JRViewController *viewController;
@property (retain, nonatomic) FBSession *session;

@end
