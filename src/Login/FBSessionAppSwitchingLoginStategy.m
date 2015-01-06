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

#import "FBSessionAppSwitchingLoginStategy.h"

#import "FBLogger.h"
#import "FBSession+Internal.h"
#import "FBSessionAuthLogger.h"
#import "FBSessionFacebookAppWebLoginStategy.h"
#import "FBSessionLoginStrategy.h"
#import "FBSessionSafariLoginStategy.h"
#import "FBUtility.h"

// A composite login strategy that tries strategies that require app switching
// (e.g., native gdp, native web gdp, safari)
@interface FBSessionAppSwitchingLoginStategy ()

@property (copy, nonatomic, readwrite) NSString *methodName;

@end

@implementation FBSessionAppSwitchingLoginStategy

- (instancetype)init {
    if ((self = [super init])) {
        self.methodName = FBSessionAuthLoggerAuthMethodFBApplicationNative;
    }
    return self;
}

- (void)dealloc {
    [_methodName release];
    [super dealloc];
}

- (BOOL)tryPerformAuthorizeWithParams:(FBSessionLoginStrategyParams *)params session:(FBSession *)session logger:(FBSessionAuthLogger *)logger {
    // if the device is running a version of iOS that supports multitasking,
    // try to obtain the access token from the Facebook app installed
    // on the device.
    // If the Facebook app isn't installed or it doesn't support
    // the fbauth:// URL scheme, fall back on Safari for obtaining the access token.
    // This minimizes the chance that the user will have to enter his or
    // her credentials in order to authorize the application.
    BOOL isMultitaskingSupported = [FBUtility isMultitaskingSupported];
    BOOL isURLSchemeRegistered = [session isURLSchemeRegistered];;

    [logger addExtrasForNextEvent:@{
                                    @"isMultitaskingSupported":@(isMultitaskingSupported),
                                    @"isURLSchemeRegistered":@(isURLSchemeRegistered)
                                    }];

    if (isMultitaskingSupported &&
        isURLSchemeRegistered &&
        !TEST_DISABLE_MULTITASKING_LOGIN) {

        NSArray *loginStrategies = @[ [[[FBSessionFacebookAppWebLoginStategy alloc] init] autorelease],
                                      [[[FBSessionSafariLoginStategy alloc] init] autorelease] ];

        for (id<FBSessionLoginStrategy> loginStrategy in loginStrategies) {

            if ([loginStrategy tryPerformAuthorizeWithParams:params session:session logger:logger]) {
                self.methodName = loginStrategy.methodName;
                return YES;
            }
        }

        [session setLoginTypeOfPendingOpenUrlCallback:FBSessionLoginTypeNone];
    }
    return NO;
}

@end
