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

#import "FBWebAppBridgeScheme.h"

#import "FBAppBridgeScheme+Subclass.h"
#import "FBUtility.h"

@implementation FBWebAppBridgeScheme
{
    NSString *_method;
    NSURL *_URL;
}

+ (NSString *)schemePrefix
{
    return @"https";
}

// these class methods should not be called on this class - return nil for them all

+ (instancetype)bridgeSchemeForFBAppForShareDialogParams:(FBLinkShareParams *)params
{
    return nil;
}

+ (instancetype)bridgeSchemeForFBAppForShareDialogPhotos
{
    return nil;
}

+ (instancetype)bridgeSchemeForFBAppForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params
{
    return nil;
}

+ (instancetype)bridgeSchemeForFBAppForLike
{
    return nil;
}

+ (instancetype)bridgeSchemeForFBMessengerForShareDialogParams:(FBLinkShareParams *)params
{
    return nil;
}

+ (instancetype)bridgeSchemeForFBMessengerForShareDialogPhotos
{
    return nil;
}

+ (instancetype)bridgeSchemeForFBMessengerForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params
{
    return nil;
}

- (instancetype)initWithURL:(NSURL *)URL method:(NSString *)method
{
    if ((self = [super init])) {
        _URL = [URL copy];
        _method = [method copy];
    }
    return self;
}

- (void)dealloc
{
    [_method release];
    [_URL release];
    [super dealloc];
}

- (NSURL *)URLForMethod:(NSString *)method queryParams:(NSDictionary *)queryParams
{
    NSAssert2([method isEqualToString:_method], @"Retrieving method for %@, but expected %@.", method, _method);
    NSURL *URL = _URL;
    if (!URL.scheme) {
        NSString *prefix = [NSString stringWithFormat:@"%@://m.", [[self class] schemePrefix]];
        NSString *URLString = [FBUtility buildFacebookUrlWithPre:prefix post:nil version:@""];
        URL = [NSURL URLWithString:URL.absoluteString relativeToURL:[NSURL URLWithString:URLString]];
    }
    NSMutableDictionary *mutableQueryParams = [[NSMutableDictionary alloc] init];
    FBSession *session = [FBSession activeSession];
    NSString *redirectURLString = [NSString stringWithFormat:
                                   @"fb%@%@://bridge/%@",
                                   session.appID,
                                   session.urlSchemeSuffix,
                                   method];
    mutableQueryParams[@"ios_bundle_id"] = [[NSBundle mainBundle] bundleIdentifier];
    mutableQueryParams[@"redirect_uri"] = [NSURL URLWithString:redirectURLString];
    if (URL.query) {
        NSDictionary *baseQueryParams = [FBUtility dictionaryByParsingURLQueryPart:URL.query];
        [mutableQueryParams addEntriesFromDictionary:baseQueryParams];
    }
    [mutableQueryParams addEntriesFromDictionary:queryParams];
    NSString *queryString = [FBUtility stringBySerializingQueryParameters:mutableQueryParams];
    [mutableQueryParams release];
    return [NSURL URLWithString:[NSString stringWithFormat:
                                 @"%@://%@%@?%@",
                                 URL.scheme,
                                 URL.host,
                                 URL.path,
                                 queryString]];
}

@end
