/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKAtePublishing;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AtePublisherCreating)
@protocol FBSDKAtePublisherCreating

- (nullable id<FBSDKAtePublishing>)createPublisherWithAppID:(NSString *)appID
NS_SWIFT_NAME(createPublisher(appID:));

@end

NS_ASSUME_NONNULL_END
