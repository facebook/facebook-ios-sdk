// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@interface NavigationController : UINavigationController <UINavigationControllerDelegate>

- (IBAction)unwindToRoot:(UIStoryboardSegue *)segue;

@end
