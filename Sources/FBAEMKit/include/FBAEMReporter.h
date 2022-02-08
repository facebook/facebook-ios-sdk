/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import <FBAEMKit/FBAEMNetworking.h>
 #import <FBAEMKit/FBSKAdNetworkReporting.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMReporter)
@interface FBAEMReporter : NSObject

/**

 Configure networker used for calling Facebook AEM Graph API endpoint
 and Facebook App ID

 This function should be called in application(_:open:options:) from ApplicationDelegate
 and BEFORE [FBAEMReporter enable] function

 @param networker   An optional networker conforms to FBAEMNetworking which handles Graph API request
 @param appID   An optional Facebook app ID, if it's null, we will get it from info.plist file with key: FacebookAppID
 */
+ (void)configureWithNetworker:(nullable id<FBAEMNetworking>)networker
                         appID:(nullable NSString *)appID __attribute__((deprecated("use configureWithNetworker:appID:reporter: instead.")));

/**

 Configure networker used for calling Facebook AEM Graph API endpoint
 and Facebook App ID

 This function should be called in application(_:open:options:) from ApplicationDelegate
 and BEFORE [FBAEMReporter enable] function. We will use SKAdNetwork reporter to prevent
 double counting.

 @param networker   An optional networker conforms to FBAEMNetworking which handles Graph API request
 @param appID   An optional Facebook app ID, if it's null, we will get it from info.plist file with key: FacebookAppID
 @param reporter   The SKAdNetwork repoter
 */
+ (void)configureWithNetworker:(nullable id<FBAEMNetworking>)networker
                         appID:(nullable NSString *)appID
                      reporter:(nullable id<FBSKAdNetworkReporting>)reporter;

/**

 Enable AEM reporting

 This function should be called in application(_:open:options:) from ApplicationDelegate
 */
+ (void)enable;

/**
 Control whether to enable conversion filtering

 This function should be called in application(_:open:options:) from ApplicationDelegate
 */
+ (void)setConversionFilteringEnabled:(BOOL)enabled;

/**
 Control whether to enable catalog matching

 This function should be called in application(_:open:options:) from ApplicationDelegate
 */
+ (void)setCatalogMatchingEnabled:(BOOL)enabled;

/**

 Handle deeplink

 This function should be called in application(_:open:options:) from ApplicationDelegate
 */
+ (void)handleURL:(NSURL *)url;

/**

 Calculate the conversion value for the app event based on the AEM configuration

 This function should be called when you log any in-app events
 */

// UNCRUSTIFY_FORMAT_OFF
+ (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value
                  parameters:(nullable NSDictionary<NSString *, id> *)parameters
NS_SWIFT_NAME(recordAndUpdate(event:currency:value:parameters:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
