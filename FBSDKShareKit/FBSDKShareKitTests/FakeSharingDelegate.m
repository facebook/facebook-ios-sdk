/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FakeSharingDelegate.h"

@implementation FakeSharingDelegate

- (void)sharer:(nonnull id<FBSDKSharing>)sharer didCompleteWithResults:(nonnull NSDictionary<NSString *, id> *)results
{
  self.capturedResults = results;
}

- (void)sharer:(nonnull id<FBSDKSharing>)sharer didFailWithError:(nonnull NSError *)error
{
  self.capturedError = error;
}

- (void)sharerDidCancel:(nonnull id<FBSDKSharing>)sharer
{
  self.didCancel = true;
}

@end
