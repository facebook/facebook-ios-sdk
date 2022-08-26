/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareDialogConfiguration.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKServerConfiguration.h"

@interface FBSDKShareDialogConfiguration ()

@property (nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;

@end

@implementation FBSDKShareDialogConfiguration

- (instancetype)init
{
  return [self initWithServerConfigurationProvider:FBSDKServerConfigurationManager.shared];
}

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
{
  if ((self = [super init])) {
    _serverConfigurationProvider = serverConfigurationProvider;
  }
  return self;
}

- (NSString *)defaultShareMode
{
  return self.serverConfigurationProvider.cachedServerConfiguration.defaultShareMode;
}

- (BOOL)shouldUseNativeDialogForDialogName:(NSString *)dialogName
{
  return [self.serverConfigurationProvider.cachedServerConfiguration
          useNativeDialogForDialogName:dialogName];
}

- (BOOL)shouldUseSafariViewControllerForDialogName:(NSString *)dialogName
{
  return [self.serverConfigurationProvider.cachedServerConfiguration
          useSafariViewControllerForDialogName:dialogName];
}

@end

#endif
