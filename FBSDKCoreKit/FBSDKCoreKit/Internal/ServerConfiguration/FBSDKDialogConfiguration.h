/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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
                 appVersions:(NSArray *)appVersions
NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, readonly) NSArray *appVersions;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSURL *URL;

@end

NS_ASSUME_NONNULL_END
