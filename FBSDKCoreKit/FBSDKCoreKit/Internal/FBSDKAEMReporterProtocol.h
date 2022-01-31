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

/// An internal protocol used to describe an AEM Reporter
NS_SWIFT_NAME(AEMReporterProtocol)
@protocol FBSDKAEMReporter

+ (void)enable;

// UNCRUSTIFY_FORMAT_OFF
+ (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value
                  parameters:(nullable NSDictionary<NSString *, id> *)parameters
  NS_SWIFT_NAME(recordAndUpdate(event:currency:value:parameters:));
// UNCRUSTIFY_FORMAT_ON

+ (void)setConversionFilteringEnabled:(BOOL)enabled;

+ (void)setCatalogMatchingEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END

#endif
