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

#import "FBFrictionlessRequestSettings.h"

#import "Facebook.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// private interface
//
@interface FBFrictionlessRequestSettings () <FBRequestDelegate>

@property (readwrite, retain) NSArray *allowedRecipients;
@property (readwrite, retain) FBRequest *activeRequest;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FBFrictionlessRequestSettings

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (instancetype)init {
    if ((self = [super init])) {
        // start life with an empty frictionless cache
        self.allowedRecipients = [[[NSArray alloc] init] autorelease];
    }
    return self;
}

- (void)enableWithFacebook:(Facebook *)facebook {
    if (!_enabled) {
        _enabled = YES;
        if (facebook) {
            [self reloadRecipientCacheWithFacebook:facebook];
        }
    }
}

- (void)reloadRecipientCacheWithFacebook:(Facebook *)facebook {
    // request the list of frictionless recipients from the server
    id request = [facebook requestWithGraphPath:@"me/apprequestformerrecipients"
                                    andDelegate:self];
    if (request) {
        self.activeRequest = request;
    }
}

- (NSArray *)recipientIDs {
    return self.allowedRecipients;
}

- (void)updateRecipientCacheWithRecipients:(NSArray *)ids {
    // if setting recipients directly, no need to complete pending request
    self.activeRequest = nil;

    if (ids == nil) {
        self.allowedRecipients = [[[NSArray alloc] init] autorelease];
    } else {
        self.allowedRecipients = [[[NSArray alloc] initWithArray:ids] autorelease];
    }
}

- (BOOL)isFrictionlessEnabledForRecipient:(NSString *)fbid {
    // trim whitespace from edges
    fbid = [fbid stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];

    // linear search through cache for a match
    for (NSString *entry in self.allowedRecipients) {
        if ([entry isEqualToString:fbid]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isFrictionlessEnabledForRecipients:(NSArray *)fbids {
    // we handle arrays of NSString and NSNumber, and throw on anything else
    for (id fbid in fbids) {
        NSString *fbidstr;
        // give us a number, and we convert it to a string
        if ([fbid isKindOfClass:[NSNumber class]]) {
            fbidstr = [(NSNumber *)fbid stringValue];
        } else if ([fbid isKindOfClass:[NSString class]]) {
            // or give us a string, and we just use it as is
            fbidstr = (NSString *)fbid;
        } else {
            // unexpected type found in the array of fbids
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"items in fbids must be NSString or NSNumber"
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   [fbid class], @"invalid class",
                                                   nil]];
        }

        // if we miss our cache once, we fail the set
        if (![self isFrictionlessEnabledForRecipient:fbidstr]) {
            return NO;
        }
    }
    return YES;
}

- (void)updateRecipientCacheWithRequestResult:(id)result {
    // a little request bookkeeping
    self.activeRequest = nil;

    NSUInteger items = [[result objectForKey: @"data"] count];
    NSMutableArray *recipients = [[[NSMutableArray alloc] initWithCapacity: items] autorelease];

    for (NSUInteger i = 0; i < items; i++) {
        [recipients addObject: [[[result objectForKey: @"data"]
                                 objectAtIndex: i]
                                objectForKey: @"recipient_id"]] ;
    }

    self.allowedRecipients = recipients;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate
- (void)request:(FBRequest *)request
        didLoad:(id)result {
    [self updateRecipientCacheWithRequestResult:result];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    // if the request to load the frictionless recipients fails, proceed without updating
    // the recipients cache; the cache may become invalid due to a failed update or other reasons
    // (e.g. simultaneous use of the same app from multiple devices), in the case of an invalid
    // cache, a request dialog may either appear a moment later than it usually would, or appear
    // briefly when it should not appear at all; in either case the correct request behavior
    // occurs, and the cache is updated
    self.activeRequest = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (void)dealloc {
    self.activeRequest = nil;
    self.allowedRecipients = nil;
    [super dealloc];
}

@end
