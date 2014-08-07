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

#import "FBRequest.h"

@interface FBRequest ()

/*!
 @abstract
 Gets or sets the flag indicating if this request can close the session in case
 of errors (like invalid sessions). For example, implicit requests like app events
 logging should not close the session. Defaults to YES.

 @discussion
 For simplicity, setting this flag to NO also bypasses any errorBehavior retry logic.
 */
@property (assign, nonatomic) BOOL canCloseSessionOnError;

@property (assign, nonatomic) BOOL skipClientToken;

@property (readonly) NSString *versionPart;

// Deprecated rest API helper methods only kept for internal use
@property (nonatomic, copy) NSString *restMethod;

- (instancetype)initWithSession:(FBSession *)session
                     restMethod:(NSString *)restMethod
                     parameters:(NSDictionary *)parameters
                     HTTPMethod:(NSString *)HTTPMethod;
@end
