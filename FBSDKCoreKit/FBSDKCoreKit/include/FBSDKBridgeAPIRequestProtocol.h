/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>

@protocol FBSDKBridgeAPIProtocol;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
NS_SWIFT_NAME(BridgeAPIRequestProtocol)
@protocol FBSDKBridgeAPIRequest <NSObject, NSCopying>

@property (nonatomic, copy, readonly) NSString *scheme;
@property (nonatomic, copy, readonly) NSString *actionID;
@property (nonatomic, nullable, copy, readonly) NSString *methodName;
@property (nonatomic, assign, readonly) FBSDKBridgeAPIProtocolType protocolType;
@property (nonatomic, nullable, readonly, strong) id<FBSDKBridgeAPIProtocol> protocol;

- (nullable NSURL *)requestURL:(NSError *_Nullable *)errorRef;

@end

NS_ASSUME_NONNULL_END

#endif
