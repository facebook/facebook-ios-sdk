/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCreateContextDialogFactory.h"

#import <FBSDKCoreKit/FBSDKAccessTokenProtocols.h>

#import "FBSDKContextDialogs+Showable.h"

@interface FBSDKCreateContextDialogFactory ()

@property (nonatomic) Class<FBSDKAccessTokenProviding> tokenProvider;

@end

@implementation FBSDKCreateContextDialogFactory

- (instancetype)initWithTokenProvider:(Class<FBSDKAccessTokenProviding>)tokenProvider
{
  if ((self = [super init])) {
    _tokenProvider = tokenProvider;
  }

  return self;
}

- (nullable id<FBSDKShowable>)makeCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                    windowFinder:(id<FBSDKWindowFinding>)windowFinder
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  if ([self.tokenProvider currentAccessToken] == nil) {
    return nil;
  }

  return [FBSDKCreateContextDialog dialogWithContent:content
                                        windowFinder:windowFinder
                                            delegate:delegate];
}

@end
