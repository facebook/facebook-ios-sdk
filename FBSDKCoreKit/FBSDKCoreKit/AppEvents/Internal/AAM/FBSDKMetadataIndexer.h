/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKMetadataIndexing.h"
#import "FBSDKSwizzling.h"
#import "FBSDKUserDataPersisting.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MetadataIndexer)
@interface FBSDKMetadataIndexer : NSObject <FBSDKMetadataIndexing>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithUserDataStore:(id<FBSDKUserDataPersisting>)userDataStore
                             swizzler:(Class<FBSDKSwizzling>)swizzler
  NS_DESIGNATED_INITIALIZER;

- (void)enable;

@end

NS_ASSUME_NONNULL_END

#endif
