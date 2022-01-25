/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKHybridAppEventsScriptMessageHandler.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventsWKWebViewKeys.h"
#import "FBSDKEventLogging.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const FBSDKAppEventsWKWebViewMessagesPixelReferralParamKey = @"_fb_pixel_referral_id";

@protocol FBSDKEventLogging;
@class WKUserContentController;

@interface FBSDKHybridAppEventsScriptMessageHandler ()

@property (nonatomic, weak) id<FBSDKEventLogging> eventLogger;
@property (nonatomic) id<FBSDKLoggingNotifying> loggingNotifier;

@end

@implementation FBSDKHybridAppEventsScriptMessageHandler

- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
                    loggingNotifier:(id<FBSDKLoggingNotifying>)loggingNotifier
{
  if ((self = [super init])) {
    _eventLogger = eventLogger;
    _loggingNotifier = loggingNotifier;
  }
  return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
  if ([message.name isEqualToString:FBSDKAppEventsWKWebViewMessagesHandlerKey]) {
    NSDictionary<NSString *, id> *body = [FBSDKTypeUtility dictionaryValue:message.body];
    if (!body) {
      return;
    }
    NSString *event = body[FBSDKAppEventsWKWebViewMessagesEventKey];
    if ([event isKindOfClass:NSString.class] && (event.length > 0)) {
      NSString *stringedParams = [FBSDKTypeUtility stringValueOrNil:body[FBSDKAppEventsWKWebViewMessagesParamsKey]];
      NSMutableDictionary<FBSDKAppEventParameterName, id> *params = nil;
      NSError *jsonParseError = nil;
      if (stringedParams) {
        params = [FBSDKTypeUtility JSONObjectWithData:[stringedParams dataUsingEncoding:NSUTF8StringEncoding]
                                              options:NSJSONReadingMutableContainers
                                                error:&jsonParseError
        ];
      }
      NSString *pixelID = body[FBSDKAppEventsWKWebViewMessagesPixelIDKey];
      if (pixelID == nil) {
        [self.loggingNotifier logAndNotify:@"Can't bridge an event without a referral Pixel ID. Check your webview Pixel configuration."];
        return;
      }
      if (jsonParseError != nil || ![params isKindOfClass:[NSDictionary<NSString *, id> class]] || params == nil) {
        [self.loggingNotifier logAndNotify:@"Could not find parameters for your Pixel request. Check your webview Pixel configuration."];
        params = [@{FBSDKAppEventsWKWebViewMessagesPixelReferralParamKey : pixelID} mutableCopy];
      } else {
        [FBSDKTypeUtility dictionary:params setObject:pixelID forKey:FBSDKAppEventsWKWebViewMessagesPixelReferralParamKey];
      }
      [self.eventLogger logInternalEvent:event
                              parameters:params
                      isImplicitlyLogged:NO];
    }
  }
}

@end

NS_ASSUME_NONNULL_END

#endif
