/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBAppCall.h"

@interface FBAppCall (Internal)

// Defined here for the rest of the SDK to use
@property (readonly) BOOL isValid;

// Re-defined here as readwrite to allow the rest of the SDK to set these
// properties
@property (nonatomic, readwrite, retain) NSError *error;
@property (nonatomic, readwrite, retain) FBDialogsData *dialogData;
@property (nonatomic, readwrite, retain) FBAppLinkData *appLinkData;
@property (nonatomic, readwrite, retain) FBAccessTokenData *accessTokenData;

- (id)initWithID:(NSString *)ID;

@end
