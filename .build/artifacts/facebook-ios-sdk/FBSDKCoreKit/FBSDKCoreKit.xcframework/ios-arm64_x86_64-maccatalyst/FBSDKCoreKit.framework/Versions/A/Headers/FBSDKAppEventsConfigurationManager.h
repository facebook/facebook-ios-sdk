/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppEventsConfigurationProviding.h>

typedef void (^FBSDKAppEventsConfigurationManagerBlock)(void);
@protocol FBSDKDataPersisting;
@protocol FBSDKSettings;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKAppEventsConfiguration;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsConfigurationManager)
@interface FBSDKAppEventsConfigurationManager : NSObject <FBSDKAppEventsConfigurationProviding>

@property (class, nonatomic, readonly) FBSDKAppEventsConfigurationManager *shared;

@property (nonatomic, readonly) id<FBSDKAppEventsConfiguration> cachedAppEventsConfiguration;

#if !DEBUG
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
#endif

// UNCRUSTIFY_FORMAT_OFF
- (void)     configureWithStore:(id<FBSDKDataPersisting>)store
                       settings:(id<FBSDKSettings>)settings
            graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
NS_SWIFT_NAME(configure(store:settings:graphRequestFactory:graphRequestConnectionFactory:));
// UNCRUSTIFY_FORMAT_ON

- (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationManagerBlock)block;

@end

NS_ASSUME_NONNULL_END
