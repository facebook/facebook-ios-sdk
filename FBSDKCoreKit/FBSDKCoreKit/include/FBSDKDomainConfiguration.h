/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(_DomainConfiguration)
@interface FBSDKDomainConfiguration : NSObject <NSCopying, NSObject, NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


- (instancetype)initWithTimestamp:(nullable NSDate *)timestamp
                       domainInfo:(nullable NSDictionary<NSString *, NSDictionary<NSString *, id>*> *)domainInfo
NS_DESIGNATED_INITIALIZER;

@property (nullable, nonatomic, readonly, copy) NSDate *timestamp;
@property (nonatomic, readonly) NSInteger version;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, NSDictionary<NSString *, id>*> *domainInfo;

/**
 Internal  method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 
 @warning INTERNAL - DO NOT USE
 */
+ (void)setDefaultDomainInfo;

@end

NS_ASSUME_NONNULL_END
