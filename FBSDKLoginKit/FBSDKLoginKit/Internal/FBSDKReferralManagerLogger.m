/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKReferralManagerLogger.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKLoginAppEventName.h"
#import "FBSDKLoginConstants.h"
#import "FBSDKReferralManagerResult.h"

static NSString *const FBSDKReferralManagerLoggerParamIdentifierKey = @"0_logger_id";
static NSString *const FBSDKReferralManagerLoggerParamTimestampKey = @"1_timestamp_ms";
static NSString *const FBSDKReferralManagerLoggerParamResultKey = @"2_result";
static NSString *const FBSDKReferralManagerLoggerParamErrorCodeKey = @"3_error_code";
static NSString *const FBSDKReferralManagerLoggerParamErrorMessageKey = @"4_error_message";
static NSString *const FBSDKReferralManagerLoggerParamExtrasKey = @"5_extras";
static NSString *const FBSDKReferralManagerLoggerParamLoggingTokenKey = @"6_logging_token";

static NSString *const FBSDKReferralManagerLoggerValueEmpty = @"";

static NSString *const FBSDKReferralManagerLoggerResultSuccessString = @"success";
static NSString *const FBSDKReferralManagerLoggerResultCancelString = @"cancelled";
static NSString *const FBSDKReferralManagerLoggerResultErrorString = @"error";

@interface FBSDKReferralManagerLogger ()

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSMutableDictionary<NSString *, id> *extras;
@property (nonatomic) NSString *loggingToken;

@end

@implementation FBSDKReferralManagerLogger

- (instancetype)init
{
  if (self = [super init]) {
    NSString *loggingToken = [FBSDKServerConfigurationProvider new].loggingToken;
    _identifier = [NSUUID UUID].UUIDString;
    _extras = [NSMutableDictionary dictionary];
    _loggingToken = [loggingToken copy];
  }
  return self;
}

- (void)logReferralStart
{
  [self logEvent:FBSDKAppEventNameFBReferralStart params:[self _parametersForNewEvent]];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)logReferralEnd:(nullable FBSDKReferralManagerResult *)result error:(nullable NSError *)error
{
  NSString *resultString = FBSDKReferralManagerLoggerValueEmpty;

  if (error != nil) {
    resultString = FBSDKReferralManagerLoggerResultErrorString;
  } else if (result.isCancelled) {
    resultString = FBSDKReferralManagerLoggerResultCancelString;
  } else if (result.referralCodes) {
    resultString = FBSDKReferralManagerLoggerResultSuccessString;
  }

  NSMutableDictionary<NSString *, id> *params = [self _parametersForNewEvent];
  [FBSDKTypeUtility dictionary:params setObject:resultString forKey:FBSDKReferralManagerLoggerParamResultKey];

  if ([error.domain isEqualToString:FBSDKErrorDomain] || [error.domain isEqualToString:FBSDKLoginErrorDomain]) {
    NSString *errorMessage = error.userInfo[@"error_message"] ?: error.userInfo[FBSDKErrorLocalizedDescriptionKey];
    [FBSDKTypeUtility dictionary:params
                       setObject:errorMessage
                          forKey:FBSDKReferralManagerLoggerParamErrorMessageKey];

    NSString *errorCode = error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] ?: [NSString stringWithFormat:@"%ld", (long)error.code];
    [FBSDKTypeUtility dictionary:params
                       setObject:errorCode
                          forKey:FBSDKReferralManagerLoggerParamErrorCodeKey];

    NSError *innerError = error.userInfo[NSUnderlyingErrorKey];
    if (innerError != nil) {
      NSString *innerErrorMessage = innerError.userInfo[@"error_message"] ?: innerError.userInfo[NSLocalizedDescriptionKey];
      [FBSDKTypeUtility dictionary:_extras
                         setObject:innerErrorMessage
                            forKey:@"inner_error_message"];

      NSString *innerErrorCode = innerError.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] ?: [NSString stringWithFormat:@"%ld", (long)innerError.code];
      [FBSDKTypeUtility dictionary:_extras
                         setObject:innerErrorCode
                            forKey:@"inner_error_code"];
    }
  } else if (error) {
    [FBSDKTypeUtility dictionary:params
                       setObject:@(error.code)
                          forKey:FBSDKReferralManagerLoggerParamErrorCodeKey];
    [FBSDKTypeUtility dictionary:params
                       setObject:error.localizedDescription
                          forKey:FBSDKReferralManagerLoggerParamErrorMessageKey];
  }

  [self logEvent:FBSDKAppEventNameFBReferralEnd params:params];
}

#pragma clang diagnostic pop

- (NSMutableDictionary<NSString *, id> *)_parametersForNewEvent
{
  NSMutableDictionary<NSString *, id> *eventParameters = [NSMutableDictionary new];

  // NOTE: We ALWAYS add all params to each event, to ensure predictable mapping on the backend.
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:_identifier ?: FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamIdentifierKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:@(round(1000 * [NSDate date].timeIntervalSince1970))
                        forKey:FBSDKReferralManagerLoggerParamTimestampKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamResultKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamErrorCodeKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamErrorMessageKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamExtrasKey];
  [FBSDKTypeUtility dictionary:eventParameters
                     setObject:_loggingToken ?: FBSDKReferralManagerLoggerValueEmpty
                        forKey:FBSDKReferralManagerLoggerParamLoggingTokenKey];

  return eventParameters;
}

- (void)logEvent:(FBSDKAppEventName)eventName params:(nullable NSMutableDictionary<NSString *, id> *)params
{
  if (_identifier) {
    NSString *extrasJSONString = [FBSDKBasicUtility JSONStringForObject:_extras
                                                                  error:NULL
                                                   invalidObjectHandler:NULL];
    if (extrasJSONString) {
      [FBSDKTypeUtility dictionary:params
                         setObject:extrasJSONString
                            forKey:FBSDKReferralManagerLoggerParamExtrasKey];
    }
    [_extras removeAllObjects];

    [FBSDKAppEvents.shared logInternalEvent:eventName
                                 parameters:params
                         isImplicitlyLogged:YES];
  }
}

@end

#endif
