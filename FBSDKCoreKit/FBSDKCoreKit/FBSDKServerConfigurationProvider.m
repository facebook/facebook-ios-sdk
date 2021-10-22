/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKServerConfigurationProvider.h"

#import "FBSDKServerConfigurationManager.h"

@implementation FBSDKServerConfigurationProvider

- (NSString *)loggingToken
{
  return FBSDKServerConfigurationManager.shared.cachedServerConfiguration.loggingToken;
}

- (NSUInteger)cachedSmartLoginOptions
{
  return FBSDKServerConfigurationManager.shared.cachedServerConfiguration.smartLoginOptions;
}

- (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName
{
  return [FBSDKServerConfigurationManager.shared.cachedServerConfiguration useSafariViewControllerForDialogName:dialogName];
}

- (void)loadServerConfigurationWithCompletionBlock:(nullable FBSDKLoginTooltipBlock)completionBlock
{
  [FBSDKServerConfigurationManager.shared loadServerConfigurationWithCompletionBlock:^(FBSDKServerConfiguration *_Nullable serverConfiguration, NSError *_Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!completionBlock) {
        return;
      }

      if (serverConfiguration && !error) {
        FBSDKLoginTooltip *loginTooltip = [[FBSDKLoginTooltip alloc] initWithText:serverConfiguration.loginTooltipText enabled:serverConfiguration.loginTooltipEnabled];
        completionBlock(loginTooltip, nil);
      } else {
        completionBlock(nil, error);
      }
    });
  }];
}

@end
