/*
 * Copyright 2013 Facebook
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

#import "FBFrictionlessDialogSupportDelegate.h"
#import "FBFrictionlessRequestSettings.h"
#import "FBUtility.h"
#import "FBSession+Internal.h"
#import "FBFrictionlessRecipientCache.h"

@interface FBFrictionlessRecipientCache () <FBFrictionlessDialogSupportDelegate>
@property (nonatomic, readwrite) BOOL frictionlessShouldMakeViewInvisible;
@property (nonatomic, readwrite, retain) FBFrictionlessRequestSettings *frictionlessSettings;
@end

@implementation FBFrictionlessRecipientCache 

@synthesize frictionlessSettings = _frictionlessSettings;
@synthesize frictionlessShouldMakeViewInvisible = _frictionlessShouldMakeViewInvisible;

- (id)init {
    self = [super init];
    if (self) {
        self.frictionlessSettings = [[[FBFrictionlessRequestSettings alloc] init] autorelease];
        [self.frictionlessSettings enableWithFacebook:nil]; // sets the flag on
    }
    return self;
}

- (void)dealloc {
    self.frictionlessSettings = nil;
    [super dealloc];
}

- (NSArray *)recipientIDs {
    return self.frictionlessSettings.recipientIDs;
}

- (void)setRecipientIDs:(NSArray *)recipientIDs {
    [self.frictionlessSettings updateRecipientCacheWithRecipients:recipientIDs];
}

- (BOOL)isFrictionlessRecipient:(id)fbid {
    // we support NSString, NSNumber and dictionary with id-key of string or number
    return [self.frictionlessSettings isFrictionlessEnabledForRecipient:[FBUtility stringFBIDFromObject:fbid]];
}

- (BOOL)areFrictionlessRecipients:(NSArray*)fbids {
    // we handle arrays of NSString, NSNumber, or dictionary with id-key of string or number
    // and return NO on anything else
    for (id fbid in fbids) {
        // if we miss our cache once, we fail the set
        if (![self isFrictionlessRecipient:fbid]) {
            return NO;
        }
    }
    return YES;
}

- (void)prefetchAndCacheForSession:(FBSession *)session {
    [self prefetchAndCacheForSession:session
                   completionHandler:nil];
}

- (void)prefetchAndCacheForSession:(FBSession *)session
                 completionHandler:(FBRequestHandler)handler {
    
    // if a session isn't specified, fall back to active session when available
    if (!session) {
        session = [FBSession activeSessionIfOpen];
    }
    
    [[[[FBRequest alloc] initWithSession:session
                               graphPath:@"me/apprequestformerrecipients"]
      autorelease]
     startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
         [self.frictionlessSettings updateRecipientCacheWithRequestResult:result];
         if (handler) {
             handler(connection, result, error);
         }
     }];
}

- (void)webDialogsWillPresentDialog:(NSString *)dialog
                         parameters:(NSMutableDictionary *)parameters
                            session:(FBSession *)session {
    
    // this method adds fricitonless behaviors to a dialog presentation, if the
    // dialog is an apprequests dialog; noop if a non-apprequests dialog
    if ([dialog isEqualToString:@"apprequests"]) {
        
        // frictionless parameter means:
        //  a. show the "Don't show this again for these friends" checkbox
        //  b. if the developer is sending a targeted request, then skip the loading screen
        [parameters setValue:@"1" forKey:@"frictionless"];
        // get_frictionless_recipients parameter means: request the frictionless recipient list encoded in the success url
        [parameters setValue:@"1" forKey:@"get_frictionless_recipients"];
        
        self.frictionlessShouldMakeViewInvisible = NO;
        
        // set invisible if all recipients are enabled for frictionless requests
        id fbid = [parameters objectForKey:@"to"];
        if (fbid != nil) {
            // if value parses as a json array expression get the list that way
            id fbids = [FBUtility simpleJSONDecode:fbid];
            if (![fbids isKindOfClass:[NSArray class]]) {
                // otherwise separate by commas (handles the singleton case too)
                fbids = [fbid componentsSeparatedByString:@","];
            }
            self.frictionlessShouldMakeViewInvisible = [self.frictionlessSettings isFrictionlessEnabledForRecipients:fbids];
        }
    }
}

@end
