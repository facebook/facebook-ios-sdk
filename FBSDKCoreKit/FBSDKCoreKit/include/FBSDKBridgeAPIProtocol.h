/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FBSDKBridgeAPIAppIDKey;
FOUNDATION_EXPORT NSString *const FBSDKBridgeAPISchemeSuffixKey;
FOUNDATION_EXPORT NSString *const FBSDKBridgeAPIVersionKey;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(BridgeAPIProtocol)
@protocol FBSDKBridgeAPIProtocol <NSObject>

// UNCRUSTIFY_FORMAT_OFF
- (nullable NSURL *)requestURLWithActionID:(NSString *)actionID
                                    scheme:(NSString *)scheme
                                methodName:(NSString *)methodName
                                parameters:(NSDictionary<NSString *, id> *)parameters
                                     error:(NSError *_Nullable *)errorRef
NS_SWIFT_NAME(requestURL(actionID:scheme:methodName:parameters:));
// UNCRUSTIFY_FORMAT_ON

// UNCRUSTIFY_FORMAT_OFF
- (nullable NSDictionary<NSString *, id> *)responseParametersForActionID:(NSString *)actionID
                                                         queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                                                               cancelled:(nullable BOOL *)cancelledRef
                                                                   error:(NSError *_Nullable *)errorRef
NS_SWIFT_NAME(responseParameters(actionID:queryParameters:cancelled:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
