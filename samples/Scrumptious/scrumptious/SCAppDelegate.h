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

@class SCViewController;
@class SCLoginViewController;

// Scrumptious sample application
//
// The purpose of the Scrumptious sample application is to demonstrate a complete real-world
// application that includes Facebook integration, friend picker, place picker, and Open Graph
// Action creation and posting.
@interface SCAppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) SCViewController *mainViewController;
@property (strong, nonatomic) SCLoginViewController* loginViewController;
@property BOOL isNavigating;

- (void)resetMainViewController;
@end
