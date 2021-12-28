/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKAppLink;

/**
 Provides a set of utilities for working with NSURLs, such as parsing of query parameters
 and handling for App Link requests.
 */
NS_SWIFT_NAME(AppLinkURL)
@interface FBSDKURL : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Creates a link target from a raw URL.
 On success, this posts the FBSDKAppLinkParseEventName measurement event. If you are constructing the FBSDKURL within your application delegate's
 application:openURL:sourceApplication:annotation:, you should instead use URLWithInboundURL:sourceApplication:
 to support better FBSDKMeasurementEvent notifications
 @param url The instance of `NSURL` to create FBSDKURL from.
 */

// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)URLWithURL:(NSURL *)url
NS_SWIFT_NAME(init(url:));
// UNCRUSTIFY_FORMAT_ON

/**
 Creates a link target from a raw URL received from an external application. This is typically called from the app delegate's
 application:openURL:sourceApplication:annotation: and will post the FBSDKAppLinkNavigateInEventName measurement event.
 @param url The instance of `NSURL` to create FBSDKURL from.
 @param sourceApplication the bundle ID of the app that is requesting your app to open the URL. The same sourceApplication in application:openURL:sourceApplication:annotation:
 */

// UNCRUSTIFY_FORMAT_OFF
+ (instancetype)URLWithInboundURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
NS_SWIFT_NAME(init(inboundURL:sourceApplication:));
// UNCRUSTIFY_FORMAT_ON

/**
 Gets the target URL.  If the link is an App Link, this is the target of the App Link.
 Otherwise, it is the url that created the target.
 */
@property (nonatomic, readonly, strong) NSURL *targetURL;

/**
 Gets the query parameters for the target, parsed into an NSDictionary.
 */
@property (nonatomic, readonly, strong) NSDictionary<NSString *, id> *targetQueryParameters;

/**
 If this link target is an App Link, this is the data found in al_applink_data.
 Otherwise, it is nil.
 */
@property (nullable, nonatomic, readonly, strong) NSDictionary<NSString *, id> *appLinkData;

/**
 If this link target is an App Link, this is the data found in extras.
 */
@property (nullable, nonatomic, readonly, strong) NSDictionary<NSString *, id> *appLinkExtras;

/**
 The App Link indicating how to navigate back to the referer app, if any.
 */
@property (nullable, nonatomic, readonly, strong) id<FBSDKAppLink> appLinkReferer;

/**
 The URL that was used to create this FBSDKURL.
 */
@property (nonatomic, readonly, strong) NSURL *inputURL;

/**
 The query parameters of the inputURL, parsed into an NSDictionary.
 */
@property (nonatomic, readonly, strong) NSDictionary<NSString *, id> *inputQueryParameters;

/**
 The flag indicating whether the URL comes from auto app link
*/
@property (nonatomic, readonly, getter = isAutoAppLink) BOOL isAutoAppLink;

@end

NS_ASSUME_NONNULL_END

#endif
