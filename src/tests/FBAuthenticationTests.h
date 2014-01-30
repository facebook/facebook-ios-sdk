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

#import <SenTestingKit/SenTestingKit.h>

@class FBTestBlocker;

// Methods in the base class will generate successful results using these strings

extern NSString *const kAuthenticationTestValidToken;
extern NSString *const kAuthenticationTestAppId;

@interface FBAuthenticationTests : SenTestCase {
@protected

    FBTestBlocker *_blocker;
}

- (void)mockSession:(id)mockSession
supportSystemAccount:(BOOL)supportSystemAccount;

- (void)mockSession:(id)mockSession
expectSystemAccountAuth:(BOOL)expect
            succeed:(BOOL)succeed;

- (void)mockSession:(id)mockSession
supportMultitasking:(BOOL)supportMultitasking;

- (void)mockSession:(id)mockSession
expectFacebookAppAuth:(BOOL)expect
                try:(BOOL)try
results:(NSDictionary *)results;

- (void)mockSession:(id)mockSession
   expectSafariAuth:(BOOL)expect
                try:(BOOL)try
results:(NSDictionary *)results;

- (void)mockSession:(id)mockSession
expectLoginDialogAuth:(BOOL)expect
            succeed:(BOOL)succeed;

@end
