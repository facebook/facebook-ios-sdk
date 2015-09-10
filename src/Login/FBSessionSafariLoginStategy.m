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

#import "FBSessionSafariLoginStategy.h"

#import "FBDialogConfig.h"
#import "FBLogger.h"
#import "FBSession+Internal.h"
#import "FBSessionAuthLogger.h"
#import "FBSessionLoginStrategy.h"
#import "FBUtility.h"

@implementation FBSessionSafariLoginStategy {
    NSString *_methodName;
}

- (instancetype)init {
    if ((self = [super init])) {
        _methodName = FBSessionAuthLoggerAuthMethodBrowser;
    }
    return self;
}

- (void)dealloc {
    [_methodName release];
    [super dealloc];
}

- (BOOL)tryPerformAuthorizeWithParams:(FBSessionLoginStrategyParams *)params session:(FBSession *)session logger:(FBSessionAuthLogger *)logger {
    if (params.trySafariAuth) {
        BOOL useSFVC = ( [FBDialogConfig useSafariViewControllerForDialogName:FBDialogConfigurationNameLogin] &&
                        session == [FBSession activeSessionIfExists] );
        if (useSFVC) {
            _methodName = FBSessionAuthLoggerAuthMethodSFVC;
        }

        NSDictionary *clientState = @{FBSessionAuthLoggerParamAuthMethodKey: self.methodName,
                                      FBSessionAuthLoggerParamIDKey : logger.ID ?: @""};
        params.webParams[FBLoginUXClientState] = [session jsonClientStateWithDictionary:clientState];

        return [session authorizeUsingSafari:params.webParams useSFVC:useSFVC];
    }
    return NO;
}

- (NSString *)methodName {
    return _methodName;
}

@end

