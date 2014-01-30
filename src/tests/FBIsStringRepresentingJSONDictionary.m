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

#import "FBIsStringRepresentingJSONDictionary.h"
#import "FBUtility.h"
#import <OCHamcrestIOS/HCDescription.h>
#import <OCHamcrestIOS/HCWrapInMatcher.h>

@implementation FBIsStringRepresentingJSONDictionary

+ (instancetype)isStringRepresentingJSONDictionary:(id<HCMatcher>)aValueMatcher
{
    return [[self alloc] initWithValue:aValueMatcher];
}

- (instancetype)initWithValue:(id<HCMatcher>)aValueMatcher
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

- (BOOL)matches:(id)string describingMismatchTo:(id<HCDescription>)mismatchDescription
{
    if (![string isKindOfClass:[NSString class]]) {
        [super describeMismatchOf:string to:mismatchDescription];
        return NO;
    }

    NSDictionary *dict = [FBUtility simpleJSONDecode:string];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        [[mismatchDescription appendText:@"no JSON dictionary in "]
         appendDescriptionOf:string];
        return NO;
    }

    if (![valueMatcher matches:dict]) {
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
    [description appendText:@"a string representing a JSON dictionary { "];
    [description appendDescriptionOf:valueMatcher];
    [description appendText:@"}"];
}

@end

#pragma mark -

id<HCMatcher> FB_representsJSONDictionary(id valueMatcher)
{
    return [FBIsStringRepresentingJSONDictionary isStringRepresentingJSONDictionary:
            HCWrapInMatcher(valueMatcher)];
}
