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

#import "FBTaggableFriendPickerViewController.h"

#import "FBError.h"
#import "FBGraphObjectPagingLoader.h"


@implementation FBTaggableFriendPickerViewController

#pragma mark - Custom Properties

- (NSSet *)fieldsForRequest {
    return nil;
}

- (void)setFieldsForRequest:(NSSet *)fieldsForRequest {
    [[NSException exceptionWithName:FBInvalidOperationException
                             reason:@"FBTaggableFriendPickerViewController: Invalid call to "
      @"-setFieldsForRequest:, which is an unsupported property on this view controller."
                           userInfo:nil]
     raise];
}

#pragma mark - internal members

+ (FBGraphObjectPagingMode)graphObjectPagingMode {
    return FBGraphObjectPagingModeImmediate;
}

+ (NSString *)firstRenderLogString {
    return @"Taggable Friend Picker: first render ";
}

+ (NSString *)graphAPIName {
    return @"taggable_friends";
}

@end
