// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginDetailsViewController.h"

@import FBSDKCoreKit;

@interface LoginDetailsViewController ()

@property (nonatomic, strong) IBOutlet UILabel *requestedPermissionsLabel;
@property (nonatomic, strong) IBOutlet UILabel *accessTokenLabel;
@property (nonatomic, strong) IBOutlet UILabel *grantedPermissionsLabel;
@property (nonatomic, strong) IBOutlet UILabel *declinedPermissionsLabel;
@property (nonatomic, strong) IBOutlet UILabel *authenticationTokenLabel;
@property (nonatomic, strong) IBOutlet UILabel *nonceLabel;
@property (nonatomic, strong) IBOutlet UILabel *profileLabel;

@end

@implementation LoginDetailsViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  FBSDKAccessToken *accessToken = FBSDKAccessToken.currentAccessToken;
  FBSDKAuthenticationToken *authenticationToken = FBSDKAuthenticationToken.currentAuthenticationToken;
  FBSDKProfile *profile = FBSDKProfile.currentProfile;

  self.requestedPermissionsLabel.text = [self permissionsFromSet:[NSSet setWithArray:self.selectedPermissions]]
  ?: @"No permissions were/will be requested";
  self.accessTokenLabel.text = accessToken.tokenString ?: @"Access Token Unavailable";
  self.grantedPermissionsLabel.text = [self permissionsFromSet:accessToken.permissions]
  ?: [self permissionsFromSet:self.result.grantedPermissions]
    ?: @"No granted permissions found";
  self.declinedPermissionsLabel.text = [self permissionsFromSet:accessToken.declinedPermissions]
  ?: [self permissionsFromSet:self.result.declinedPermissions]
    ?: @"No declined permissions found";
  self.authenticationTokenLabel.text = authenticationToken.tokenString ?: @"Auth Token Unavailable";
  self.nonceLabel.text = authenticationToken.nonce ?: @"Auth Token Nonce Unavailable";

  NSString *ageRangeText = profile.ageRange
  ? [NSString stringWithFormat:@"{min: %@, max:%@}", profile.ageRange.min, profile.ageRange.max]
  : nil;
  NSString *hometownText = profile.hometown
  ? [NSString stringWithFormat:@"{id: %@, name:%@}", profile.hometown.id, profile.hometown.name]
  : nil;
  NSString *locationText = profile.location
  ? [NSString stringWithFormat:@"{id: %@, name:%@}", profile.location.id, profile.location.name]
  : nil;
  self.profileLabel.text = [NSString stringWithFormat:@"User ID: %@ \nUser Name: %@ \nUser First Name: %@ \nUser Middle Name %@ \nUser Last Name: %@\nEmail:%@ \nProfileImageUrl: %@\nGender: %@ \nUser Link: %@ \nFriends: %@ \nBirthday: %@ \nAge Range: %@\nHometown: %@\nLocation: %@",
                            profile.userID,
                            profile.name,
                            profile.firstName,
                            profile.middleName,
                            profile.lastName,
                            profile.email,
                            profile.imageURL.absoluteString,
                            profile.gender,
                            profile.linkURL,
                            profile.friendIDs.description,
                            profile.birthday,
                            ageRangeText,
                            hometownText,
                            locationText];
}

- (NSString *)permissionsFromSet:(NSSet<NSString *> *)permissions
{
  if (permissions.count == 0) {
    return nil;
  }

  NSString *permissionsString = [[NSArray arrayWithObjects:permissions.allObjects, nil] componentsJoinedByString:@","];
  if (permissionsString.length > 1) {
    return permissionsString;
  } else {
    return nil;
  }
}

- (IBAction)copyAccessTokenToClipboard:(id)sender
{
  [[UIPasteboard generalPasteboard] setString:self.accessTokenLabel.text];
}

- (IBAction)copyAuthenticationTokenToClipboard:(id)sender
{
  [[UIPasteboard generalPasteboard] setString:self.authenticationTokenLabel.text];
}

@end
