// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKLoginManagerLogger.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKLoginError.h"

static NSString *const FBSDKLoginManagerLoggingClientStateKey = @"state";
static NSString *const FBSDKLoginManagerLoggingClientStateIsClientState = @"com.facebook.sdk_client_state";

static NSString *const FBSDKLoginManagerLoggerParamIdentifierKey = @"0_auth_logger_id";
static NSString *const FBSDKLoginManagerLoggerParamTimestampKey = @"1_timestamp_ms";
static NSString *const FBSDKLoginManagerLoggerParamResultKey = @"2_result";
static NSString *const FBSDKLoginManagerLoggerParamLoginBehaviorKey = @"3_method";
static NSString *const FBSDKLoginManagerLoggerParamErrorCodeKey = @"4_error_code";
static NSString *const FBSDKLoginManagerLoggerParamErrorMessageKey = @"5_error_message";
static NSString *const FBSDKLoginManagerLoggerParamExtrasKey = @"6_extras";

static NSString *const FBSDKLoginManagerLoggerValueEmpty = @"";

static NSString *const FBSDKLoginManagerLoggerNativeBehavior = @"fb_application_web_auth";
static NSString *const FBSDKLoginManagerLoggerBrowserBehavior = @"browser_auth";
static NSString *const FBSDKLoginManagerLoggerSystemAccountBehavior = @"integrated_auth";
static NSString *const FBSDKLoginManagerLoggerWebViewBehavior = @"fallback_auth";

static NSString *const FBSDKLoginManagerLoggerResultSuccessString = @"success";
static NSString *const FBSDKLoginManagerLoggerResultCancelString = @"cancelled";
static NSString *const FBSDKLoginManagerLoggerResultErrorString = @"error";
static NSString *const FBSDKLoginManagerLoggerResultSkippedString = @"skipped";

NSString *const FBSDKLoginManagerLoggerTryNative = @"tryFBAppAuth";
NSString *const FBSDKLoginManagerLoggerTryBrowser = @"trySafariAuth";
NSString *const FBSDKLoginManagerLoggerTrySystemAccount = @"tryIntegratedAuth";
NSString *const FBSDKLoginManagerLoggerTryWebView = @"tryFallback";

@implementation FBSDKLoginManagerLogger
{
@private
  NSString *_identifier;
  NSMutableDictionary *_extras;

  NSString *_lastResult;
  NSError *_lastError;

  FBSDKLoginBehavior _loginBehavior;
}

+ (FBSDKLoginManagerLogger *)loggerFromParameters:(NSDictionary *)parameters
{
  NSDictionary *clientState = [FBSDKInternalUtility objectForJSONString:parameters[FBSDKLoginManagerLoggingClientStateKey] error:NULL];

  id isClientState = clientState[FBSDKLoginManagerLoggingClientStateIsClientState];
  if ([isClientState isKindOfClass:[NSNumber class]] && [isClientState boolValue]) {
    NSString *identifier = clientState[FBSDKLoginManagerLoggerParamIdentifierKey];
    NSNumber *loginBehavior = clientState[FBSDKLoginManagerLoggerParamLoginBehaviorKey];

    if (identifier && loginBehavior) {
      FBSDKLoginManagerLogger *logger = [[self alloc] init];
      if (logger != nil) {
        logger->_identifier = identifier;
        logger->_loginBehavior = [loginBehavior unsignedIntegerValue];
        return logger;
      }
    }
  }
  return nil;
}

- (instancetype)init
{
  if ((self = [super init]) != nil) {
    _identifier = [[NSUUID UUID] UUIDString];
    _extras = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)startEventWithBehavior:(FBSDKLoginBehavior)loginBehavior isReauthorize:(BOOL)isReauthorize
{
  BOOL willTryNative = NO;
  BOOL willTryBrowser = NO;
  BOOL willTrySystemAccount = NO;
  BOOL willTryWebView = NO;

  switch (loginBehavior) {
    case FBSDKLoginBehaviorNative:
      willTryNative = YES;
      willTryBrowser = YES;
      break;
    case FBSDKLoginBehaviorBrowser:
      willTryBrowser = YES;
      break;
    case FBSDKLoginBehaviorSystemAccount:
      willTryNative = YES;
      willTryBrowser = YES;
      willTrySystemAccount = YES;
      break;
    case FBSDKLoginBehaviorWeb:
      willTryWebView = YES;
      break;
  }

  [_extras addEntriesFromDictionary:@{
    FBSDKLoginManagerLoggerTryNative : @(willTryNative),
    FBSDKLoginManagerLoggerTryBrowser : @(willTryBrowser),
    FBSDKLoginManagerLoggerTrySystemAccount : @(willTrySystemAccount),
    FBSDKLoginManagerLoggerTryWebView : @(willTryWebView),
    @"isReauthorize" : @(isReauthorize),
  }];

  [self logEvent:FBSDKAppEventNameFBSessionAuthStart params:[self parametersForNewEventWithBehavior:NULL]];
}

- (void)endEvent
{
    [self logEvent:FBSDKAppEventNameFBSessionAuthEnd result:_lastResult error:_lastError];
}

- (void)startLoginWithBehavior:(FBSDKLoginBehavior)loginBehavior
{
  _loginBehavior = loginBehavior;
  [self logEvent:FBSDKAppEventNameFBSessionAuthMethodStart params:[self parametersForNewEventWithBehavior:&loginBehavior]];
}

- (void)endLoginWithResult:(FBSDKLoginManagerLoggerResult)result error:(NSError *)error
{
  NSString *resultString = FBSDKLoginManagerLoggerValueEmpty;

  switch (result) {
    case FBSDKLoginManagerLoggerResultSuccess:
      resultString = FBSDKLoginManagerLoggerResultSuccessString;
      break;
    case FBSDKLoginManagerLoggerResultCancel:
      resultString = FBSDKLoginManagerLoggerResultCancelString;
      break;
    case FBSDKLoginManagerLoggerResultError:
      resultString = FBSDKLoginManagerLoggerResultErrorString;
      break;
    case FBSDKLoginManagerLoggerResultSkipped:
      resultString = FBSDKLoginManagerLoggerResultSkippedString;
      break;
  }

  _lastResult = resultString;
  _lastError = error;

  [self logEvent:FBSDKAppEventNameFBSessionAuthMethodEnd result:resultString error:error];
}

- (NSDictionary *)parametersWithTimeStampAndClientState:(NSDictionary *)loginParams forLoginBehavior:(FBSDKLoginBehavior)loginBehavior
{
  NSMutableDictionary *params = [loginParams mutableCopy];

  NSNumber *timeValue = @(round(1000 * [[NSDate date] timeIntervalSince1970]));
  NSString *e2eTimestampString = [FBSDKInternalUtility JSONStringForObject:@{ @"init" : timeValue }
                                                                     error:NULL
                                                      invalidObjectHandler:NULL];
  params[@"e2e"] = e2eTimestampString;

  params[FBSDKLoginManagerLoggingClientStateKey] = [self clientStateForBehavior:loginBehavior];

  return params;
}

- (void)willAttemptAppSwitchingBehavior
{
  NSString *defaultUrlScheme = [NSString stringWithFormat:@"fb%@%@", [FBSDKSettings appID], [FBSDKSettings appURLSchemeSuffix] ?: @""];
  BOOL isURLSchemeRegistered = [FBSDKInternalUtility isRegisteredURLScheme:defaultUrlScheme];

  [_extras addEntriesFromDictionary:@{
    @"isMultitaskingSupported" : @([UIDevice currentDevice].isMultitaskingSupported),
    @"isURLSchemeRegistered" : @(isURLSchemeRegistered),
  }];
}

- (void)systemAuthDidShowDialog:(BOOL)didShowDialog isUnTOSedDevice:(BOOL)isUnTOSedDevice
{
  [_extras addEntriesFromDictionary:@{
    @"isUntosedDevice" : @(isUnTOSedDevice),
    @"dialogShown" : @(didShowDialog),
  }];
}

#pragma mark - Private

- (NSString *)clientStateForBehavior:(FBSDKLoginBehavior)loginBehavior
{
  NSDictionary *clientState = @{
    FBSDKLoginManagerLoggerParamLoginBehaviorKey: @(loginBehavior),
    FBSDKLoginManagerLoggerParamIdentifierKey: _identifier,
    FBSDKLoginManagerLoggingClientStateIsClientState: @YES,
  };

  return [FBSDKInternalUtility JSONStringForObject:clientState error:NULL invalidObjectHandler:NULL];
}

- (NSString *)identifierForBehavior:(FBSDKLoginBehavior)loginBehavior
{
  NSString *behavior = FBSDKLoginManagerLoggerValueEmpty;
  switch (loginBehavior) {
    case FBSDKLoginBehaviorNative:
      behavior = FBSDKLoginManagerLoggerNativeBehavior;
      break;
    case FBSDKLoginBehaviorBrowser:
      behavior = FBSDKLoginManagerLoggerBrowserBehavior;
      break;
    case FBSDKLoginBehaviorSystemAccount:
      behavior = FBSDKLoginManagerLoggerSystemAccountBehavior;
      break;
    case FBSDKLoginBehaviorWeb:
      behavior = FBSDKLoginManagerLoggerWebViewBehavior;
      break;
  }
  return behavior;
}

- (NSMutableDictionary *)parametersForNewEventWithBehavior:(const FBSDKLoginBehavior *)loginBehavior
{
    NSMutableDictionary *eventParameters = [[NSMutableDictionary alloc] init];

    // NOTE: We ALWAYS add all params to each event, to ensure predictable mapping on the backend.
    eventParameters[FBSDKLoginManagerLoggerParamIdentifierKey] = _identifier ?: FBSDKLoginManagerLoggerValueEmpty;
    eventParameters[FBSDKLoginManagerLoggerParamTimestampKey] = [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])];
    eventParameters[FBSDKLoginManagerLoggerParamResultKey] = FBSDKLoginManagerLoggerValueEmpty;
    eventParameters[FBSDKLoginManagerLoggerParamLoginBehaviorKey] = (loginBehavior != NULL ? [self identifierForBehavior:*loginBehavior] : FBSDKLoginManagerLoggerValueEmpty);
    eventParameters[FBSDKLoginManagerLoggerParamErrorCodeKey] = FBSDKLoginManagerLoggerValueEmpty;
    eventParameters[FBSDKLoginManagerLoggerParamErrorMessageKey] = FBSDKLoginManagerLoggerValueEmpty;
    eventParameters[FBSDKLoginManagerLoggerParamExtrasKey] = FBSDKLoginManagerLoggerValueEmpty;

    return eventParameters;
}

- (void)logEvent:(NSString *)eventName params:(NSMutableDictionary *)params
{
  if (_identifier) {
    NSString *extrasJSONString = [FBSDKInternalUtility JSONStringForObject:_extras
                                                                     error:NULL
                                                      invalidObjectHandler:NULL];
    if (extrasJSONString) {
        params[FBSDKLoginManagerLoggerParamExtrasKey] = extrasJSONString;
    }
    [_extras removeAllObjects];

    [FBSDKAppEvents logImplicitEvent:eventName valueToSum:nil parameters:params accessToken:nil];
  }
}

- (void)logEvent:(NSString *)eventName result:(NSString *)result error:(NSError *)error
{
  NSMutableDictionary *params = [self parametersForNewEventWithBehavior:&_loginBehavior];

  params[FBSDKLoginManagerLoggerParamResultKey] = result;

  if ([error.domain isEqualToString:FBSDKErrorDomain] || [error.domain isEqualToString:FBSDKLoginErrorDomain]) {
    // tease apart the structure.

    // first see if there is an explicit message in the error's userInfo. If not, default to the reason,
    // which is less useful.
    NSString *value = error.userInfo[@"error_message"] ?: error.userInfo[FBSDKErrorLocalizedDescriptionKey];
    [FBSDKInternalUtility dictionary:params setObject:value forKey:FBSDKLoginManagerLoggerParamErrorMessageKey];

    value = error.userInfo[FBSDKGraphRequestErrorGraphErrorCode] ?: [NSString stringWithFormat:@"%ld", (long)error.code];
    [FBSDKInternalUtility dictionary:params setObject:value forKey:FBSDKLoginManagerLoggerParamErrorCodeKey];

    NSError *innerError = error.userInfo[NSUnderlyingErrorKey];
    if (innerError != nil) {
      value = innerError.userInfo[@"error_message"] ?: innerError.userInfo[NSLocalizedDescriptionKey];
      [FBSDKInternalUtility dictionary:_extras setObject:value forKey:@"inner_error_message"];

      value = innerError.userInfo[FBSDKGraphRequestErrorGraphErrorCode] ?: [NSString stringWithFormat:@"%ld", (long)innerError.code];
      [FBSDKInternalUtility dictionary:_extras setObject:value forKey:@"inner_error_code"];
    }
  } else if (error) {
    params[FBSDKLoginManagerLoggerParamErrorCodeKey] = @(error.code);
  }

  [self logEvent:eventName params:params];
}

@end
