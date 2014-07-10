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

#import "FBLikeDialogParams.h"

#import "FBError.h"

@implementation FBLikeDialogParams

#pragma mark - Object Lifecycle

- (void)dealloc
{
    [_objectID release];
    [super dealloc];
}

#pragma mark - Internal Methods

- (NSDictionary *)dictionaryMethodArgs
{
    NSString *objectID = self.objectID;
    return (objectID ?
            @{ @"object_id": objectID } :
            @{});
}

- (NSError *)validate
{
    if (!self.objectID) {
        return [NSError errorWithDomain:FacebookSDKDomain
                                   code:FBErrorDialog
                               userInfo:@{ FBErrorDialogReasonKey: FBErrorDialogInvalidLikeObjectID }];
    }
    return nil;
}

+ (NSString *)methodName {
    return @"like";
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    FBLikeDialogParams *copy = [super copyWithZone:zone];
    copy->_objectID = [_objectID copyWithZone:zone];
    return copy;
}

@end
