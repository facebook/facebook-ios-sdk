// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "TokenViewController.h"

#import "Console.h"

@implementation TokenViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self _updateTokenLabels:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateTokenLabels:) name:FBSDKAccessTokenDidChangeNotification object:nil];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)refreshToken:(id)sender
{
  [FBSDKAccessToken refreshCurrentAccessTokenWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (error) {
      ConsoleError(error, @"Error refreshing permiossions");
    } else {
      [self markTestCompleteWithSender:sender];
    }
  }];
}

- (IBAction)copyTokenToClipboard:(id)sender
{
  [[UIPasteboard generalPasteboard] setString:self.tokenStringLabel.text];
}

- (void)_updateTokenLabels:(NSNotification *)notification
{
  self.tokenStringLabel.text = [FBSDKAccessToken currentAccessToken].tokenString;
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm"];
  self.expirationDateLabel.text = ([FBSDKAccessToken currentAccessToken]
    ? [NSString stringWithFormat:@"%@%@", [dateFormatter stringFromDate:[FBSDKAccessToken currentAccessToken].expirationDate], [FBSDKAccessToken currentAccessToken].isExpired ? @" (Expired)" : @""]
    : @"");
  self.dataAccessExpirationDateLabel.text = ([FBSDKAccessToken currentAccessToken]
    ? [NSString stringWithFormat:@"%@%@", [dateFormatter stringFromDate:[FBSDKAccessToken currentAccessToken].dataAccessExpirationDate], [FBSDKAccessToken currentAccessToken].isDataAccessExpired ? @" (Expired)" : @""]
    : @"");
  self.grantedPermissionsLabel.text = [[[FBSDKAccessToken currentAccessToken].permissions allObjects] componentsJoinedByString:@","];
  self.declinedPermissionsLabel.text = [[[FBSDKAccessToken currentAccessToken].declinedPermissions allObjects] componentsJoinedByString:@","];
  self.expiredPermissionsLabel.text = [[[FBSDKAccessToken currentAccessToken].expiredPermissions allObjects] componentsJoinedByString:@","];
  self.graphDomainLabel.text = FBSDKAuthenticationToken.currentAuthenticationToken.graphDomain;
}

@end
