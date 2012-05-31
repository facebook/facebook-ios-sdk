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

@implementation FBContentLink

@synthesize targetURL = _targetURL;
@synthesize actionTypes = _actionTypes;
@synthesize source = _source;
@synthesize ref =_ref;
@synthesize originalQueryParameters = _originalQueryParameters;

- (id)initWithURL:(NSURL*)url {
    if (self = [super init]) {
        NSString *query = [url fragment];
        NSDictionary *params = [FBUtility dictionaryByParsingURLQueryPart:query];
    
        _targetURL = [[NSURL alloc] initWithString:[params valueForKey:@"target_url"]];
        _actionTypes = [[params valueForKey:@"fb_action_types"] componentsSeparatedByString:@","];
        _source = [params valueForKey:@"fb_source"];
        _ref = [[params valueForKey:@"fb_ref"] componentsSeparatedByString:@","];
        _originalQueryParameters = params;
    }
    return self;
}

- (void)dealloc
{
    [_targetURL release];
    [_actionTypes release];
    [_source release];
    [_ref release];
    [_originalQueryParameters release];
    [super dealloc];
}

@end
