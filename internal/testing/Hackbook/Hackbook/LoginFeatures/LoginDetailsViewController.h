// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@import FBSDKLoginKit;

#import "LoginViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoginDetailsViewController : LoginViewController

@property (nonatomic) FBSDKLoginManagerLoginResult *result;

@end

NS_ASSUME_NONNULL_END
