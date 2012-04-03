/*
 * Copyright 2012 Facebook
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

#import "FBSessionManualTokenCachingStrategy.h"

@implementation FBSessionManualTokenCachingStrategy 

@synthesize accessToken = _accessToken,
            expirationDate = _expirationDate;

- (void)dealloc {
    [_accessToken release];
    [_expirationDate release];
    [super dealloc];
}

- (void)cacheToken:(NSString*)token expirationDate:(NSDate*)date
{
    self.accessToken = token;
    self.expirationDate = date;
}

- (NSString*)fetchTokenAndExpirationDate:(NSDate**)date
{
    // to adhere to interface of the base, we won't return anything partial
    if (self.accessToken && self.expirationDate) {
        *date = self.expirationDate;
        return self.accessToken;
    }
    return nil;
}

- (void)clearToken:(NSString*)token
{
    self.accessToken = nil;
    self.expirationDate = nil;
}

@end