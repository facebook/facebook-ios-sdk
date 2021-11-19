/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "FBSDKEventLogging.h"
#import "FBSDKLoggingNotifying.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(HybridAppEventsScriptMessageHandler)
@interface FBSDKHybridAppEventsScriptMessageHandler : NSObject <WKScriptMessageHandler>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
                  loggingNotifier:(id<FBSDKLoggingNotifying>)loggingNotifier
NS_SWIFT_NAME(init(eventLogger:loggingNotifier:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
