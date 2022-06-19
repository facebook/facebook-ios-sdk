// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "FBSDKPlatformShareExtension.h"

BOOL FBSDKPlatformShareExtensionCanOpen(void)
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbapi20150629://"]];
}
