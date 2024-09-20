/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKMetadataIndexing.h>
#import <Foundation/Foundation.h>

@protocol FBSDKUserDataPersisting;
@protocol FBSDKSwizzling;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_MetadataIndexer)
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
