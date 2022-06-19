// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@import FBSDKLoginKit;

#import "../Console.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoginViewController : UIViewController

@property (nonatomic, copy) NSArray<NSString *> *selectedPermissions;

- (BOOL)isLoggedIn;
- (void)showLoginDetails;
- (void)showLoginDetailsForResult:(FBSDKLoginManagerLoginResult *)result;
- (void)showLoginDetailsForResult:(FBSDKLoginManagerLoginResult *)result
             requestedPermissions:(NSArray *)permissions;
@end

NS_ASSUME_NONNULL_END
