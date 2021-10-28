/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKNumberParsing <NSObject>

- (NSNumber *)parseNumberFrom:(NSString *)string;

@end

NS_SWIFT_NAME(AppEventsNumberParser)
@interface FBSDKAppEventsNumberParser : NSObject <FBSDKNumberParsing>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithLocale:(NSLocale *)locale;

@end

NS_ASSUME_NONNULL_END
