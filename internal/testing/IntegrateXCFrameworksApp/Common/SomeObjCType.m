// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "SomeObjCType.h"

@import FBSDKCoreKit;
@import FBSDKCoreKit_Basics;
@import FBSDKLoginKit;
@import FBSDKShareKit;

#import "TargetConditionals.h"

#if !TARGET_OS_TV
@import FBAEMKit;
@import FBSDKGamingServicesKit;
#endif

@implementation SomeObjCType

- (void)doStuff
{
  NSLog(@"%@", FBSDKAccessToken.currentAccessToken);
  NSLog(@"%@", FBSDKAuthenticationToken.currentAuthenticationToken);
  FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] initWithImage:[UIImage new] isUserGenerated:YES];
  NSLog(@"%@", photo.caption);

#if !TARGET_OS_TV
  NSLog(@"%@", [[[FBSDKLoginConfiguration alloc] initWithTracking:FBSDKLoginTrackingLimited] description]);
  NSLog(@"%@", [[FBSDKLoginManager new] description]);
  NSLog(@"%@", [[[FBSDKCreateContextContent alloc] initDialogContentWithPlayerID:@"5"] description]);
#endif
}

@end
