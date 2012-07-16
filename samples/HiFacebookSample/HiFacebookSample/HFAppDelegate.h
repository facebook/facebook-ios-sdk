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
#import <FacebookSDK/FacebookSDK.h>

// Hi Facebook sample application
//
// The purpose of this sample application is to show an ultra-lightweight approach to
// integrating Facebook into your application to support login, friend selection and
// posting. This sample uses the high-level abstraction FBMyData, which is designed to
// provide a low-friction integration experience that handles certain very common 
// Facebook integration needs.
// These include:
// - tracking changes in user identity using FBMyData
// - fetching and displaying additional user data using FBMyData
// - use of FBProfilePictureView to display a profile picture
// - how to post a Facebook status update, optionally with a place and tags, using FBMyData
// - how to upload a photo using FBMyData
// - how to invoke the FBFriendPickerViewController to select a set of friends

@class HFViewController;

@interface HFAppDelegate : UIResponder<UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HFViewController *rootViewController;

@end
