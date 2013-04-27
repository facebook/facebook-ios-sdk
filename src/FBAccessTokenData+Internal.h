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

#import "FBAccessTokenData.h"

/*
 @abstract Internal API to FBAccessTokenData
 @discussion
   Note even though FBAccessTokenData should be treated as immutable
 with respect to the public surface area, we provide internal
 read-write fields to support backwards compatibility with
 older logic.
*/
@interface FBAccessTokenData (Internal)

@property (nonatomic, readwrite, copy) NSDate *refreshDate;
@property (nonatomic, readwrite, copy) NSArray *permissions;

@end
