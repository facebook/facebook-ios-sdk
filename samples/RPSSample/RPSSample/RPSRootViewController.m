/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RPSRootViewController.h"

#import "RPSAutoAppLinkDebugTool.h"
#import "RPSGameViewController.h"

@implementation RPSRootViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.tabBarController = [[UITabBarController alloc] init];

  UIViewController *gameViewController;
  if ([UIDevice.currentDevice userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    gameViewController = [[RPSGameViewController alloc] initWithNibName:@"RPSGameViewController_iPhone" bundle:nil];
  } else {
    gameViewController = [[RPSGameViewController alloc] initWithNibName:@"RPSGameViewController_iPad" bundle:nil];
  }

  UINavigationController *gameNavigationController = [[UINavigationController alloc] initWithRootViewController:gameViewController];
  gameViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Game" image:[UIImage imageNamed:@"game.png"] tag:0];

  UIViewController *toolViewController = [[RPSAutoAppLinkDebugTool alloc] init];
  UINavigationController *toolNavigationController = [[UINavigationController alloc] initWithRootViewController:toolViewController];
  toolViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Auto Applink Debug Tool" image:[UIImage imageNamed:@"tool.png"] tag:1];
  toolNavigationController.navigationBar.topItem.title = @"Debug Tool";

  self.tabBarController.viewControllers = @[gameNavigationController, toolNavigationController];
  [self.view addSubview:self.tabBarController.view];
}

@end
