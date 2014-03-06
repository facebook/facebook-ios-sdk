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

#import "FBShareDialogParams.h"

#import "FBAppBridge.h"
#import "FBDialogsParams+Internal.h"
#import "FBError.h"
#import "FBLogger.h"
#import "FBAppBridgeScheme.h"
#import "FBUtility.h"

#ifndef FB_BUILD_ONLY
#define FB_BUILD_ONLY
#endif

#import "FBSettings.h"

#ifdef FB_BUILD_ONLY
#undef FB_BUILD_ONLY
#endif

@implementation FBShareDialogParams

- (void)dealloc
{
    [_link release];
    [_name release];
    [_caption release];
    [_description release];
    [_picture release];
    [_friends release];
    [_place release];
    [_ref release];

    [super dealloc];
}

- (NSDictionary *)dictionaryMethodArgs
{
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    if (self.link) {
        [args setObject:[self.link absoluteString] forKey:@"link"];
    }
    if (self.name) {
        [args setObject:self.name forKey:@"name"];
    }
    if (self.caption) {
        [args setObject:self.caption forKey:@"caption"];
    }
    if (self.description) {
        [args setObject:self.description forKey:@"description"];
    }
    if (self.picture) {
        [args setObject:[self.picture absoluteString] forKey:@"picture"];
    }
    if (self.friends) {
        NSMutableArray *tags = [NSMutableArray arrayWithCapacity:self.friends.count];
        for (id tag in self.friends) {
            [tags addObject:[FBUtility stringFBIDFromObject:tag]];
        }
        [args setObject:tags forKey:@"tags"];
    }
    if (self.place) {
        [args setObject:[FBUtility stringFBIDFromObject:self.place] forKey:@"place"];
    }
    if (self.ref) {
        [args setObject:self.ref forKey:@"ref"];
    }
    [args setObject:[NSNumber numberWithBool:self.dataFailuresFatal] forKey:@"dataFailuresFatal"];

    return args;
}

- (NSError *)validate {
    NSString *errorReason = nil;

    if ((_link && ![FBAppBridgeScheme isSupportedScheme:_link.scheme]) ||
        (_picture && ![FBAppBridgeScheme isSupportedScheme:_picture.scheme])) {
        errorReason = FBErrorDialogInvalidShareParameters;
    }

    if (errorReason) {
        NSDictionary *userInfo = @{ FBErrorDialogReasonKey: errorReason };
        return [NSError errorWithDomain:FacebookSDKDomain
                                   code:FBErrorDialog
                               userInfo:userInfo];
    }
    return nil;
}

- (void)setLink:(NSURL *)link
{
    [_link autorelease];
    if(link && ![FBAppBridgeScheme isSupportedScheme:link.scheme]) {
        _link = nil;
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                            logEntry:@"FBShareDialogParams: only \"http\" or \"https\" schemes are supported for link shares"];
    } else {
        _link = [link copy];
    }
}

- (void)setPicture:(NSURL *)picture
{
    [_picture autorelease];
    if (picture && ![FBAppBridgeScheme isSupportedScheme:picture.scheme]) {
        _picture = nil;
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                            logEntry:@"FBShareDialogParams: only \"http\" or \"https\" schemes are supported for link thumbnails"];
    } else {
        _picture = [picture copy];
    }
}

@end
