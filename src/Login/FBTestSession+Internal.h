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

#import "FBTestSession.h"

@interface FBTestSession (Internal)

// Can be used during testing to force a request for an access token refresh. This affects only the next
// connection, when this flag is reset.
@property (readwrite) BOOL forceAccessTokenRefresh;

@property (readonly, copy) NSString *testAppClientToken;

@end
