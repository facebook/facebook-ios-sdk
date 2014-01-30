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

#import "FBAppLinkData+Internal.h"

#import "FBUtility.h"

@interface FBAppLinkData ()

@property (readwrite, retain) NSURL *targetURL;
@property (readwrite, copy) NSArray *actionTypes;
@property (readwrite, copy) NSArray *actionIDs;
@property (readwrite, copy) NSString *ref;
@property (readwrite, copy) NSDictionary *originalQueryParameters;
@property (readwrite, retain) NSURL *originalURL;
@property (readwrite, copy) NSDictionary *arguments;
@property (readwrite, copy) NSString *userAgent;
@property (readwrite, copy) NSDictionary *refererData;
@end

@implementation FBAppLinkData

- (instancetype)initWithURL:(NSURL *)url {
    NSDictionary *params = [FBUtility queryParamsDictionaryFromFBURL:url];
    NSURL *targetURL = (params[@"target_url"]) ? [[[NSURL alloc] initWithString:params[@"target_url"]] autorelease] : nil;
    NSDictionary *originalQueryParameters = params;

    if (self = [self initWithURL:url targetURL:targetURL originalParams:originalQueryParameters arguments:nil]) {
        self.actionIDs = [params[@"fb_action_ids"] componentsSeparatedByString:@","];
        self.actionTypes = [params[@"fb_action_types"] componentsSeparatedByString:@","];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
                  targetURL:(NSURL *)targetURL
             originalParams:(NSDictionary *)originalQueryParameters
                  arguments:(NSDictionary *)arguments {
    if ((self = [self init])) {
        self.originalURL = url;
        self.targetURL = targetURL;
        self.ref = nil;
        self.userAgent = nil;
        self.refererData = nil;
        self.originalQueryParameters = originalQueryParameters;
        self.arguments = arguments;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
                  targetURL:(NSURL *)targetURL
                        ref:(NSString *)ref
                  userAgent:(NSString *)userAgent
                refererData:(NSDictionary *)refererData
             originalParams:(NSDictionary *)originalQueryParameters {
    if ((self = [self init])) {
        self.originalURL = url;
        self.targetURL = targetURL;
        self.ref = ref;
        self.userAgent = userAgent;
        self.refererData = refererData;
        self.originalQueryParameters = originalQueryParameters;
        self.arguments = nil;
    }
    return self;
}

- (void)dealloc
{
    [_targetURL release];
    [_actionTypes release];
    [_actionIDs release];
    [_ref  release];
    [_originalQueryParameters  release];
    [_originalURL release];
    [super dealloc];
}

- (BOOL)isValid {
    return (self.targetURL ||
            self.actionTypes ||
            self.actionIDs ||
            self.ref);
}

+ (FBAppLinkData *)createFromURL:(NSURL *)url {
    FBAppLinkData *appLinkData = [[[FBAppLinkData alloc] initWithURL:url] autorelease];
    if (!appLinkData.isValid) {
        // Not an app link!
        appLinkData = nil;
    }
    return appLinkData;
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p",
                               NSStringFromClass([self class]),
                               self];

    if (self.targetURL) {
        [result appendFormat:@", targetURL: %@", self.targetURL.absoluteString];
    }

    if (self.ref) {
        [result appendFormat:@"\n ref: %@", self.ref];
    }

    if (self.actionIDs) {
        [result appendFormat:@"\n actionIDs: %@", self.actionIDs];
    }

    if (self.actionTypes) {
        [result appendFormat:@"\n actionTypes: %@", self.actionTypes];
    }

    [result appendString:@">"];
    return result;
}

@end
