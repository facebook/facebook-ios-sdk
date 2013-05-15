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

#import "FBAppLinkData+Internal.h"
#import "FBUtility.h"

@interface FBAppLinkData ()

@property (readwrite, retain) NSURL *targetURL;
@property (readwrite, copy) NSArray *actionTypes;
@property (readwrite, copy) NSArray *actionIDs;
@property (readwrite, copy) NSArray *ref;
@property (readwrite, copy) NSDictionary *originalQueryParameters;

@end

@implementation FBAppLinkData

- (id)initWithURL:(NSURL*)url {
    if (self = [super init]) {
        NSDictionary *params = [FBUtility queryParamsDictionaryFromFBURL:url];
        
        if (params[@"target_url"]) {
            self.targetURL = [[[NSURL alloc] initWithString:params[@"target_url"]] autorelease];
        }
        self.actionIDs = [params[@"fb_action_ids"] componentsSeparatedByString:@","];
        self.actionTypes = [params[@"fb_action_types"] componentsSeparatedByString:@","];
        self.ref = [params[@"fb_ref"] componentsSeparatedByString:@","];
        self.originalQueryParameters = params;
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

- (NSString*)description {
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
