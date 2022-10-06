/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKErrorConfigurationProtocol.h>
#import <Foundation/Foundation.h>

@protocol FBSDKGraphRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_DecodableErrorConfiguration)
@protocol FBSDKDecodableErrorConfiguration <NSObject>

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary;
- (void)updateWithArray:(NSArray<NSDictionary<NSString *, id> *> *)array;

@end

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ErrorConfiguration)
@interface FBSDKErrorConfiguration : NSObject <
  NSSecureCoding,
  NSCopying,
  FBSDKErrorConfiguration,
  FBSDKDecodableErrorConfiguration
>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// initialize from optional dictionary of existing configurations. If not supplied a fallback will be created.
- (instancetype)initWithDictionary:(nullable NSDictionary<NSString *, id> *)dictionary NS_DESIGNATED_INITIALIZER;

// parses the array (supplied from app settings endpoint)
- (void)updateWithArray:(NSArray<NSDictionary<NSString *, id> *> *)array;

// NSString "code" instances support "*" wildcard semantics (nil is treated as "*" also)
// 'request' is optional, typically for identifying special graph request semantics (e.g., no recovery for client token)
- (nullable FBSDKErrorRecoveryConfiguration *)recoveryConfigurationForCode:(nullable NSString *)code subcode:(nullable NSString *)subcode request:(id<FBSDKGraphRequest>)request;

@end

NS_ASSUME_NONNULL_END
