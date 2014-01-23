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

#import "FBIsURLHavingQueryParams.h"
#import "FBUtility.h"
#import <OCHamcrestIOS/HCDescription.h>
#import <OCHamcrestIOS/HCWrapInMatcher.h>

@implementation FBIsURLHavingQueryParams

+ (id)isURLHavingQueryParams:(id<HCMatcher>)aValueMatcher
{
    return [[self alloc] initWithValue:aValueMatcher];
}

- (id)initWithValue:(id<HCMatcher>)aValueMatcher
{
    self = [super init];
    if (self != nil)
    {
        valueMatcher = aValueMatcher;
    }
    return self;
}

- (BOOL)matches:(id)item
{
    return [self matches:item describingMismatchTo:nil];
}

- (BOOL)matches:(id)url describingMismatchTo:(id<HCDescription>)mismatchDescription
{
    if (![url isKindOfClass:[NSURL class]]) {
        [super describeMismatchOf:url to:mismatchDescription];
        return NO;
    }

    id query = [url query];
    if (![query isKindOfClass:[NSString class]]) {
        [[mismatchDescription appendText:@"no query in "]
                               appendDescriptionOf:url];
        return NO;
    }

    NSDictionary *queryParams = [FBUtility dictionaryByParsingURLQueryPart:query];
    if (![valueMatcher matches:queryParams]) {
        return NO;
    }

    return YES;
}

- (void)describeMismatchOf:(id)item to:(id<HCDescription>)mismatchDescription
{
    [self matches:item describingMismatchTo:mismatchDescription];
}

- (void)describeTo:(id<HCDescription>)description
{
    [description appendText:@"an NSURL containing query parameters { "];
    [description appendDescriptionOf:valueMatcher];
    [description appendText:@"}"];
}

@end

#pragma mark -

id<HCMatcher> FB_hasQueryParams(id valueMatcher)
{
    return [FBIsURLHavingQueryParams isURLHavingQueryParams:HCWrapInMatcher(valueMatcher)];
}
