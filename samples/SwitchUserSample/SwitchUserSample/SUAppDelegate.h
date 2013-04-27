/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "SUUserManager.h"

// Switch User sample application
//
// The purpose of this sample application is show a more advanced use of
// FBSession to manage tokens of multiple users. The idea behind this scenario
// is an application which supports devices shared by multiple users (e.g. the
// family iPad), and which remembers multiple users and lets the users easily
// switch the currently active user

@interface SUAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

// FBSample logic
// The SUUserManager class is a custom type included with this sample that shows
// lightweight user-management performed by an application, which utilizes 
// FBSession to manage login workflow and integration with Facebook
@property (strong, nonatomic) SUUserManager *userManager;

@end
