/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import <UIKit/UIKit.h>

 #import <FBSDKCoreKit/FBSDKCoreKit.h>

 #import "FBSDKBridgeAPIProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKPasteboard;

NS_SWIFT_NAME(BridgeAPIProtocolNativeV1)
@interface FBSDKBridgeAPIProtocolNativeV1 : NSObject <FBSDKBridgeAPIProtocol>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithAppScheme:(nullable NSString *)appScheme;
- (instancetype)initWithAppScheme:(nullable NSString *)appScheme
                       pasteboard:(nullable id<FBSDKPasteboard>)pasteboard
              dataLengthThreshold:(NSUInteger)dataLengthThreshold
                   includeAppIcon:(BOOL)includeAppIcon
                     errorFactory:(id<FBSDKErrorCreating>)errorFactory
  NS_DESIGNATED_INITIALIZER;

@property (nullable, nonatomic, readonly, copy) NSString *appScheme;
@property (nonatomic, readonly, assign) NSUInteger dataLengthThreshold;
@property (nonatomic, readonly, getter = shouldIncludeAppIcon, assign) BOOL includeAppIcon;
@property (nullable, nonatomic, readonly, strong) id<FBSDKPasteboard> pasteboard;
@property (nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;

@end

#endif

NS_ASSUME_NONNULL_END
