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

#import "FBPhotoParams.h"

#import "FBError.h"
#import "FBShareDialogPhotoParams.h"
#import "FBUtility.h"

@implementation FBShareDialogPhotoParams
@end

@implementation FBPhotoParams

- (instancetype)initWithPhotos:(NSArray *)photos {
  if ((self = [super init])) {
    self.photos = photos;
  }
  return self;
}

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
    NSString *errorFailureReason = nil;

    if (_photos.count == 0 || _photos.count > 6) {
        errorReason = FBErrorDialogInvalidShareParameters;
        errorFailureReason = @"You may only send between one and six (inclusive) images";
    }

    for (id photo in _photos) {
        if (photo && ![photo isKindOfClass:[UIImage class]]) {
            errorReason = FBErrorDialogInvalidShareParameters;
            errorFailureReason = @"photos must be instances of UIImage";
        }
    }

    if (errorReason) {
        NSDictionary *userInfo = @{ FBErrorDialogReasonKey: errorReason,
                                    NSLocalizedFailureReasonErrorKey : errorFailureReason };
        return [NSError errorWithDomain:FacebookSDKDomain
                                   code:FBErrorDialog
                               userInfo:userInfo];
    }
    return nil;
}

+ (NSString *)methodName {
    return @"share";
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    FBPhotoParams *copy = [super copyWithZone:zone];
    copy->_dataFailuresFatal = _dataFailuresFatal;
    copy->_friends = [_friends copyWithZone:zone];
    copy->_photos = [_photos copyWithZone:zone];
    copy->_place = [_place copyWithZone:zone];
    return copy;
}

@end
