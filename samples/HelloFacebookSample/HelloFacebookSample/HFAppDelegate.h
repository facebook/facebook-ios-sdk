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

// Hello Facebook sample application
//
// The purpose of this sample application is show how to use Facebook to 
// personalize an application experience and perform a set of typical actions.
// These include:
// - managing login and logout using FBSession
// - how to request and display additional user data using FBRequest
// - use of FBProfilePictureView to display a profile picture
// - how to post a Facebook status update
// - how to upload a photo to Facebook
// - how to invoke the FBFriendPickerViewController to select a set of friends.

@class HFViewController;

@interface HFAppDelegate : UIResponder<UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HFViewController *rootViewController;

@end
