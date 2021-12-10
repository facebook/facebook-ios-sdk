/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CodelessParameterComponent)
@interface FBSDKCodelessParameterComponent : NSObject

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *value;
@property (nonatomic, readonly) NSArray *path;
@property (nonatomic, readonly, copy) NSString *pathType;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict;
- (BOOL)isEqualToParameter:(FBSDKCodelessParameterComponent *)parameter;

@end

NS_ASSUME_NONNULL_END

#endif
