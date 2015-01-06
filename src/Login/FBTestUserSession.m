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

#import "FBTestUserSession.h"

#import "FBSession+Protected.h"
#import "FBSessionTokenCachingStrategy.h"

@interface FBTestUserSession() {
  FBAccessTokenData *_tokenData;
}

@end

@implementation FBTestUserSession

- (instancetype)initWithAccessTokenData:(FBAccessTokenData *)tokenData {
  self = [super initWithAppID:tokenData.appID
                  permissions:nil
              defaultAudience:FBSessionDefaultAudienceNone
              urlSchemeSuffix:nil
           tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
  if (self) {
    _tokenData = [tokenData copy];
  }
  return self;
}

- (void)dealloc {
  [_tokenData release];
  [super dealloc];
}

+ (instancetype)sessionWithAccessTokenData:(FBAccessTokenData *)tokenData {
  FBTestUserSession *session = [[FBTestUserSession alloc] initWithAccessTokenData:tokenData];
  return [session autorelease];
}

#pragma mark - FBSesssion overrides
- (void)authorizeWithPermissions:(NSArray *)permissions behavior:(FBSessionLoginBehavior)behavior defaultAudience:(FBSessionDefaultAudience)audience isReauthorize:(BOOL)isReauthorize {
  if (isReauthorize) {
    // For the test session, since we don't present UI,
    // we'll just complete the re-auth. Note this obviously means
    // no new permissions are requested.
    [super handleReauthorize:nil
                 accessToken:(self.treatReauthorizeAsCancellation) ? nil : self.accessTokenData.accessToken];
  } else {
    [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                      error:nil
                                  tokenData:_tokenData
                                shouldCache:NO];
  }

}

- (BOOL)shouldExtendAccessToken {
  // Note: we reset the flag each time we are queried. Tests should set it as needed for more complicated logic.
  BOOL extend = self.forceAccessTokenExtension || [super shouldExtendAccessToken];
  self.forceAccessTokenExtension = NO;
  return extend;
}

@end
