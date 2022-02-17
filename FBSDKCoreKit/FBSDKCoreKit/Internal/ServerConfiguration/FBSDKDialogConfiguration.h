/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DialogConfiguration)
@interface FBSDKDialogConfiguration : NSObject <NSCopying, NSObject, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name
                         URL:(NSURL *)URL
                 appVersions:(NSArray<id> *)appVersions
  NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSArray<id> *appVersions; // NSString, possibly NSNumber
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSURL *URL;

@end

NS_ASSUME_NONNULL_END
