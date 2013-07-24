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

/*!
 @abstract Designated initializer for FBAppCall

 @param ID  the unique identifier for matching the FBAppCall. If nil, a random uid will be generated
 @param enforceScheme a flag determining if we need to detect if the url scheme that will be used for a FAS
  is correctly configured to allow a callback from iOS. In general, if you are creating an "outbound" FBAppCall,
  you should use the default of YES to make sure the schemes are set correctly. If the scheme is not set correctly,
  a developer error is logged and this will return nil.
 @param appID the explicit app id to use. If nil, defaults to [FBSettings defaultAppID]
 @param urlSchemeSuffix the explicit url scheme suffix to use. If nil, defaults to [FBSettings defaultUrlSchemeSuffix].
 
 @discussion The app id and url scheme parameters are overrides that can be specified on an FBSession instance. In order
  to wire up bridge call backs properly, FBAppCall must know about any such overrides.
*/
- (id)initWithID:(NSString *)ID enforceScheme:(BOOL)enforceScheme appID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix;

@end
