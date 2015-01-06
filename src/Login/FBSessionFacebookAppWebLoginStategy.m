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

#import "FBSessionFacebookAppWebLoginStategy.h"

#import "FBLogger.h"
#import "FBSession+Internal.h"
#import "FBSessionAuthLogger.h"
#import "FBSessionLoginStrategy.h"
#import "FBUtility.h"

@implementation FBSessionFacebookAppWebLoginStategy

- (BOOL)tryPerformAuthorizeWithParams:(FBSessionLoginStrategyParams *)params session:(FBSession *)session logger:(FBSessionAuthLogger *)logger {
    if (params.tryFBAppAuth && !TEST_DISABLE_FACEBOOKLOGIN) {
        NSDictionary *clientState = @{FBSessionAuthLoggerParamAuthMethodKey: self.methodName,
                                      FBSessionAuthLoggerParamIDKey : logger.ID ?: @""};
        params.webParams[FBLoginUXClientState] = [session jsonClientStateWithDictionary:clientState];
        return [session authorizeUsingFacebookApplication:params.webParams];
    }
    return NO;
}

- (NSString *)methodName {
    return FBSessionAuthLoggerAuthMethodFBApplicationWeb;
}

@end
