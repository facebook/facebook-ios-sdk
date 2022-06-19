// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginViewController.h"

@import FBSDKCoreKit;

#import "LoginDetailsViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController
{
  FBSDKLoginManagerLoginResult *latestResult;
  NSArray *latestRequestedPermissions;
}

- (BOOL)isLoggedIn
{
  return ((FBSDKAccessToken.currentAccessToken) || (FBSDKAuthenticationToken.currentAuthenticationToken));
}

- (void)showLoginDetails
{
  [self performSegueWithIdentifier:@"showLoginDetails" sender:self];
}

- (void)showLoginDetailsForResult:(FBSDKLoginManagerLoginResult *)result
             requestedPermissions:(NSArray *)permissions
{
  latestResult = result;
  latestRequestedPermissions = permissions;
  [self showLoginDetails];
}

- (void)showLoginDetailsForResult:(FBSDKLoginManagerLoginResult *)result
{
  latestResult = result;
  [self showLoginDetails];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  LoginDetailsViewController *details = segue.destinationViewController;
  details.result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:latestResult.token
                                                   authenticationToken:latestResult.authenticationToken
                                                           isCancelled:latestResult.isCancelled
                                                    grantedPermissions:latestResult.grantedPermissions
                                                   declinedPermissions:latestResult.declinedPermissions];
  details.selectedPermissions = latestRequestedPermissions;
  latestResult = nil;
}

@end
