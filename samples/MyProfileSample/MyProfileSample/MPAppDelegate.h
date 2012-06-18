/*
 * Copyright 2012 Facebook
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
#import <FBiOSSDK/FacebookSDK.h>

// My Profile sample application
//
// The purpose of this sample application is show how to use Facebook to 
// personalize an application experience. This application shows how to 
// manage login and logout using FBSession, as well as how to request 
// and display additional user data using FBRequest and FBProfilePictureView.

@class MPViewController;

@interface MPAppDelegate : UIResponder<UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MPViewController *viewController;

// FBSample logic
// In this sample the app delegate maintains a property for the current 
// active session, and the view controllers reference the session via
// this property. See the "Just Login" or "Switch User" sample for more
// detailed discusison around login and token handling
@property (strong, nonatomic) FBSession *session;

@end
