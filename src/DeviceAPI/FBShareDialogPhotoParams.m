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

#import "FBShareDialogPhotoParams.h"

#import "FBError.h"
#import "FBUtility.h"

@implementation FBShareDialogPhotoParams

- (void)dealloc
{
    [_friends release];
    [_place release];
    [_photos release];

    [super dealloc];
}

- (NSDictionary *)dictionaryMethodArgs
{
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
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
    if (self.photos) {
        [args setObject:self.photos forKey:@"photos"];
    }
    [args setObject:[NSNumber numberWithBool:self.dataFailuresFatal] forKey:@"dataFailuresFatal"];

    return args;
}

- (NSError *)validate {
    NSString *errorReason = nil;

    if (_photos.count == 0) {
        errorReason = FBErrorDialogInvalidShareParameters;
    }

    for (id photo in _photos) {
        if (photo && ![photo isKindOfClass:[UIImage class]]) {
            errorReason = FBErrorDialogInvalidShareParameters;
        }
    }

    if (errorReason) {
        NSDictionary *userInfo = @{ FBErrorDialogReasonKey: errorReason };
        return [NSError errorWithDomain:FacebookSDKDomain
                                   code:FBErrorDialog
                               userInfo:userInfo];
    }
    return nil;
}

@end
