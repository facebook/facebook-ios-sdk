/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBSessionAuthLogger.h"

#import "FBAppEvents+Internal.h"
#import "FBError.h"
#import "FBUtility.h"

// NOTE: The parameters are prefixed with a number (0-9) to allow us to determine sort order.
// These keys are sorted on the backend before being mapped to custom columns. Determining the order
// on the client will make it easier to parse through logs, and will allow future columns to be mapped
// predictably on the backend.
NSString *const FBSessionAuthLoggerParamIDKey = @"0_auth_logger_id";
NSString *const FBSessionAuthLoggerParamTimestampKey = @"1_timestamp_ms";
NSString *const FBSessionAuthLoggerParamResultKey = @"2_result";
NSString *const FBSessionAuthLoggerParamAuthMethodKey = @"3_method";
NSString *const FBSessionAuthLoggerParamErrorCodeKey = @"4_error_code";
NSString *const FBSessionAuthLoggerParamErrorMessageKey = @"5_error_message";
NSString *const FBSessionAuthLoggerParamExtrasKey = @"6_extras";

NSString *const FBSessionAuthLoggerAuthMethodIntegrated = @"integrated_auth";
NSString *const FBSessionAuthLoggerAuthMethodFBApplicationNative = @"fb_application_native_auth";
NSString *const FBSessionAuthLoggerAuthMethodFBApplicationWeb = @"fb_application_web_auth";
NSString *const FBSessionAuthLoggerAuthMethodBrowser = @"browser_auth";
NSString *const FBSessionAuthLoggerAuthMethodFallback = @"fallback_auth";

NSString *const FBSessionAuthLoggerResultSuccess = @"success";
NSString *const FBSessionAuthLoggerResultError = @"error";
NSString *const FBSessionAuthLoggerResultCancelled = @"cancelled";
NSString *const FBSessionAuthLoggerResultSkipped = @"skipped";

NSString *const FBSessionAuthLoggerParamEmptyValue = @"";

@interface FBSessionAuthLogger ()

@property (nonatomic, readwrite, copy) NSString *ID;
@property (nonatomic, retain) NSMutableDictionary *extras;
@property (nonatomic, assign) FBSession *session;
@property (nonatomic, copy) NSString *authMethod;

@end

@implementation FBSessionAuthLogger

- (id)initWithSession:(FBSession *)session {
    return [self initWithSession:session
                              ID:nil
                      authMethod:nil];
}

- (id)initWithSession:(FBSession *)session ID:(NSString *)ID authMethod:(NSString *)authMethod {
    self = [super init];
    if (self) {
        self.ID = ID ?: [[FBUtility newUUIDString] autorelease];
        self.authMethod = authMethod;
        self.extras = [NSMutableDictionary dictionary];
        self.session = session;
    }
    return self;
}

- (void)dealloc {
    [_ID release];
    [_extras release];
    [_authMethod release];

    [super dealloc];
}

- (void)addExtrasForNextEvent:(NSDictionary *)extras {
    [self.extras addEntriesFromDictionary:extras];
}

- (void)logEvent:(NSString *)eventName params:(NSMutableDictionary *)params {
    if (!self.session || !self.ID) {
        return;
    }

    NSString *extrasJSONString = [FBUtility simpleJSONEncode:self.extras];
    if (extrasJSONString) {
        params[FBSessionAuthLoggerParamExtrasKey] = extrasJSONString;
    }

    [self.extras removeAllObjects];

    [FBAppEvents logImplicitEvent:eventName valueToSum:nil parameters:params session:self.session];
}

- (void)logEvent:(NSString *)eventName result:(NSString *)result error:(NSError *)error {
    NSMutableDictionary *params = [[self newEventParameters] autorelease];

    params[FBSessionAuthLoggerParamResultKey] = result;

    if ([error.domain isEqualToString:FacebookSDKDomain]) {
        // tease apart the structure.

        // first see if there is an explicit message in the error's userInfo. If not, default to the reason,
        // which is less useful.
        NSString *value = error.userInfo[@"error_message"] ?: error.userInfo[FBErrorLoginFailedReason];
        if (value) {
            params[FBSessionAuthLoggerParamErrorMessageKey] = value;
        }

        value = error.userInfo[FBErrorLoginFailedOriginalErrorCode] ?: [NSString stringWithFormat:@"%ld", (long)error.code];
        if (value) {
            params[FBSessionAuthLoggerParamErrorCodeKey] = value;
        }

        NSError *innerError = error.userInfo[FBErrorInnerErrorKey];
        value = innerError.userInfo[@"error_message"] ?: innerError.userInfo[FBErrorLoginFailedReason];
        if (value) {
            [self addExtrasForNextEvent:@{@"inner_error_message": value}];
        }

        value = innerError.userInfo[FBErrorLoginFailedOriginalErrorCode] ?: [NSString stringWithFormat:@"%ld", (long)innerError.code];
        if (value) {
            [self addExtrasForNextEvent:@{@"inner_error_code": value}];
        }
    } else if (error) {
        params[FBSessionAuthLoggerParamErrorCodeKey] = [NSNumber numberWithInteger:error.code];
    }

    [self logEvent:eventName params:params];
}

- (void)logStartAuth {
    [self logEvent:FBAppEventNameFBSessionAuthStart params:[[self newEventParameters] autorelease]];
}

- (void)logStartAuthMethod:(NSString *)authMethodName {
    self.authMethod = authMethodName;
    [self logEvent:FBAppEventNameFBSessionAuthMethodStart params:[[self newEventParameters] autorelease]];
}

- (void)logEndAuthMethodWithResult:(NSString *)result error:(NSError *)error {
    [self logEvent:FBAppEventNameFBSessionAuthMethodEnd result:result error:error];
    self.authMethod = nil;
}

- (void)logEndAuthWithResult:(NSString *)result error:(NSError *)error {
    [self logEvent:FBAppEventNameFBSessionAuthEnd result:result error:error];
}

- (NSMutableDictionary *)newEventParameters {
    NSMutableDictionary *eventParameters = [[NSMutableDictionary alloc] init];

    // NOTE: We ALWAYS add all params to each event, to ensure predictable mapping on the backend.
    eventParameters[FBSessionAuthLoggerParamIDKey] = self.ID ?: FBSessionAuthLoggerParamEmptyValue;
    eventParameters[FBSessionAuthLoggerParamTimestampKey] = [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])];
    eventParameters[FBSessionAuthLoggerParamResultKey] = FBSessionAuthLoggerParamEmptyValue;
    eventParameters[FBSessionAuthLoggerParamAuthMethodKey] = self.authMethod ?: FBSessionAuthLoggerParamEmptyValue;
    eventParameters[FBSessionAuthLoggerParamErrorCodeKey] = FBSessionAuthLoggerParamEmptyValue;
    eventParameters[FBSessionAuthLoggerParamErrorMessageKey] = FBSessionAuthLoggerParamEmptyValue;
    eventParameters[FBSessionAuthLoggerParamExtrasKey] = FBSessionAuthLoggerParamEmptyValue;

    return eventParameters;
}

@end
