/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

// Boolean OG (Rock the Logic!) sample application
//
// The purpose of this sample application is to provide an example of
// how to publish and read Open Graph actions with Facebook. The goal
// of the sample is to show how to use FBRequest, FBRequestConnection,
// and FBSession classes, as well as the FBOpenGraphAction protocol and
// related types in order to create a social app using Open Graph

@interface RPSAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) UIWindow *window;
// @property (strong, nonatomic) UITabBarController *tabBarController;
@property (nonatomic, strong) UINavigationController *navigationController;

@end
