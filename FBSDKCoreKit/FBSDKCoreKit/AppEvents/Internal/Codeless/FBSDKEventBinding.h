/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import <UIKit/UIKit.h>

 #import "FBSDKAppEventName.h"
 #import "FBSDKAppEventsNumberParser.h"
 #import "FBSDKCodelessParameterComponent.h"

NS_ASSUME_NONNULL_BEGIN

@class FBSDKCodelessPathComponent;
@protocol FBSDKEventLogging;

NS_SWIFT_NAME(EventBinding)
@interface FBSDKEventBinding : NSObject

@property (class, nonatomic, readonly) id<FBSDKNumberParsing> numberParser;
@property (nullable, nonatomic, readonly, copy) FBSDKAppEventName eventName;
@property (nullable, nonatomic, readonly, copy) NSString *eventType;
@property (nullable, nonatomic, readonly, copy) NSString *appVersion;
// patternlint-disable-next-line objc-headers-collection-generics
@property (nullable, nonatomic, readonly) NSArray<id> *path; // NSArray<FBSDKCodelessPathComponent *>
@property (nullable, nonatomic, readonly, copy) NSString *pathType;
@property (nullable, nonatomic, readonly) NSArray<FBSDKCodelessParameterComponent *> *parameters;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (BOOL) isPath:(nullable NSArray<FBSDKCodelessPathComponent *> *)path
  matchViewPath:(nullable NSArray<FBSDKCodelessPathComponent *> *)viewPath;
- (FBSDKEventBinding *)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
                        eventLogger:(id<FBSDKEventLogging>)eventLogger;
- (void)trackEvent:(nullable id)sender;
- (BOOL)isEqualToBinding:(FBSDKEventBinding *)binding;

@end

#endif

NS_ASSUME_NONNULL_END
