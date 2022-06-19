// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

@import FBSDKLoginKit;

#import "DeviceLoginViewController.h"

#import "Console.h"

@interface DeviceLoginViewController ()

@end

@implementation DeviceLoginViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  FBSDKDeviceLoginManager *loginManager = [[FBSDKDeviceLoginManager alloc]
                                           initWithPermissions:_selectedPermissions
                                           enableSmartLogin:YES];
  loginManager.delegate = self;
  [loginManager start];
}

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager startedWithCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo
{
  NSString *message = [NSString stringWithFormat:@"Log In With Code: %@", codeInfo.loginCode];
  UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Device Login" message:message preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
    ConsoleLog(@"Device Login alert cancelled");
  }];
  [controller addAction:cancelAction];
  [self presentViewController:controller animated:YES completion:nil];
}

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager completedWithResult:(FBSDKDeviceLoginManagerResult *)result error:(NSError *)error
{
  [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
    if (result.accessToken != nil) {
      ConsoleSucceed(@"Device Login success");
    } else {
      ConsoleError(error, @"Device Login error");
    }
  }];
}

@end
