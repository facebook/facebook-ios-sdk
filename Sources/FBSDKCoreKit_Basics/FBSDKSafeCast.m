/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSafeCast.h"

id _FBSDKCastToClassOrNilUnsafeInternal(id object, Class klass)
{
  return [(NSObject *)object isKindOfClass:klass] ? object : nil;
}

id _FBSDKCastToProtocolOrNilUnsafeInternal(id object, Protocol *protocol)
{
  return [(NSObject *)object conformsToProtocol:protocol] ? object : nil;
}
