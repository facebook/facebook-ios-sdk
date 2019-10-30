// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RPSRootViewController.h"

#import "RPSAutoAppLinkDebugTool.h"
#import "RPSGameViewController.h"

@implementation RPSRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tabBarController = [[UITabBarController alloc] init];

    UIViewController *gameViewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
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
