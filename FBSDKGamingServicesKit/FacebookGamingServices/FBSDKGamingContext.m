/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingContext.h"

@interface FBSDKGamingContext ()

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSInteger size;

@end

@implementation FBSDKGamingContext

static FBSDKGamingContext *_currentContext;

+ (nullable instancetype)createContextWithIdentifier:(NSString *)identifier size:(NSInteger)size
{
  if (!identifier || (identifier.length == 0)) {
    return nil;
  }
  FBSDKGamingContext *context = [FBSDKGamingContext new];
  context.identifier = identifier;
  _currentContext = context;

  if (size > 0) {
    context.size = size;
  }

  return context;
}

+ (FBSDKGamingContext *)currentContext
{
  return _currentContext;
}

+ (void)setCurrentContext:(FBSDKGamingContext *)context
{
  _currentContext = context;
}

@end
