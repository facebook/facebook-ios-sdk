/*
 * Copyright 2012 Facebook
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

#import "FBContentLink.h"
#import "FBUtility.h"

@interface FBContentLink ()

@property (readwrite, copy) NSURL *targetURL;
@property (readwrite, copy) NSArray *actionTypes;
@property (readwrite, copy) NSString *source;
@property (readwrite, copy) NSArray *ref;
@property (readwrite, copy) NSDictionary *originalQueryParameters;

@end

@implementation FBContentLink

@synthesize targetURL;
@synthesize actionTypes;
@synthesize source;
@synthesize ref;
@synthesize originalQueryParameters;

- (id)initWithURL:(NSURL*)url {
    if (self = [super init]) {
        NSString *query = [url fragment];
        NSDictionary *params = [FBUtility dictionaryByParsingURLQueryPart:query];

        self.targetURL = [[[NSURL alloc] initWithString:[params valueForKey:@"target_url"]] autorelease];
        self.actionTypes = [[params valueForKey:@"fb_action_types"] componentsSeparatedByString:@","];
        self.source = [params valueForKey:@"fb_source"];
        self.ref = [[params valueForKey:@"fb_ref"] componentsSeparatedByString:@","];
        self.originalQueryParameters = params;
    }
    return self;
}

- (void)dealloc
{
    self.targetURL = nil;
    self.actionTypes =nil;
    self.source = nil;
    self.ref = nil;
    self.originalQueryParameters = nil;
    [super dealloc];
}

@end
