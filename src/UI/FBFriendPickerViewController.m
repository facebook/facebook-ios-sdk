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

#import "FBFriendPickerViewController.h"
#import "FBFriendPickerViewController+Internal.h"

#import "FBAppEvents+Internal.h"
#import "FBError.h"
#import "FBFriendPickerCacheDescriptor.h"
#import "FBGraphObjectPickerViewController+Internal.h"
#import "FBGraphObjectTableSelection.h"

NSString *const FBFriendPickerCacheIdentity = @"FBFriendPicker";

int const FBRefreshCacheDelaySeconds = 2;

@implementation FBFriendPickerViewController

#pragma mark - Custom Properties

- (void)setSelection:(NSArray *)selection {
    [self.selectionManager selectItem:selection tableView:self.tableView];
}

#pragma mark - Public Methods

- (void)configureUsingCachedDescriptor:(FBCacheDescriptor *)cacheDescriptor {
    if (![cacheDescriptor isKindOfClass:[FBFriendPickerCacheDescriptor class]]) {
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBFriendPickerViewController: An attempt was made to configure "
          @"an instance with a cache descriptor object that was not created "
          @"by the FBFriendPickerViewController class"
                               userInfo:nil]
         raise];
    }
    FBFriendPickerCacheDescriptor *cd = (FBFriendPickerCacheDescriptor *)cacheDescriptor;
    self.userID = cd.userID;
    self.fieldsForRequest = cd.fieldsForRequest;
}

#pragma mark - public class members

+ (FBCacheDescriptor *)cacheDescriptor {
    return [[[FBFriendPickerCacheDescriptor alloc] init] autorelease];
}

+ (FBCacheDescriptor *)cacheDescriptorWithUserID:(NSString *)userID
                                fieldsForRequest:(NSSet *)fieldsForRequest {
    return [[[FBFriendPickerCacheDescriptor alloc] initWithUserID:userID
                                                 fieldsForRequest:fieldsForRequest]
            autorelease];
}

#pragma mark - internal members

+ (FBGraphObjectPagingMode)graphObjectPagingMode {
    return FBGraphObjectPagingModeImmediate;
}

+ (NSString *)firstRenderLogString {
    return @"Friend Picker: first render ";
}

+ (NSTimeInterval)cacheRefreshDelay {
    return FBRefreshCacheDelaySeconds;
}

+ (NSString *)graphAPIName {
    return @"friends";
}

+ (NSString *)cacheIdentity {
    return FBFriendPickerCacheIdentity;
}

- (void)notifyDelegateDataDidChange {
    [super notifyDelegateDataDidChange];

    id<FBFriendPickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(friendPickerViewControllerDataDidChange:)]) {
        [delegate friendPickerViewControllerDataDidChange:self];
    }
}

- (void)notifyDelegateSelectionDidChange {
    [super notifyDelegateSelectionDidChange];

    id<FBFriendPickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(friendPickerViewControllerSelectionDidChange:)]) {
        [delegate friendPickerViewControllerSelectionDidChange:self];
    }
}

- (void)notifyDelegateOfError:(NSError *)error {
    [super notifyDelegateOfError:error];

    id<FBFriendPickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(friendPickerViewController:handleError:)]) {
        [delegate friendPickerViewController:self handleError:error];
    }
}

- (BOOL)delegateIncludesGraphObject:(id<FBGraphObject>)graphObject {
    BOOL includesGraphObject = [super delegateIncludesGraphObject:graphObject];

    id<FBFriendPickerDelegate> delegate = (id)self.delegate;
    if (includesGraphObject && [delegate respondsToSelector:@selector(friendPickerViewController:shouldIncludeUser:)]) {
        id<FBGraphUser> user = (id<FBGraphUser>)graphObject;
        includesGraphObject = [delegate friendPickerViewController:self shouldIncludeUser:user];
    }
    return includesGraphObject;
}

#pragma mark - private members

- (void)logAppEvents:(BOOL)cancelled {
    [FBAppEvents logImplicitEvent:FBAppEventNameFriendPickerUsage
                       valueToSum:nil
                       parameters:@{ FBAppEventParameterDialogOutcome : (cancelled
                                                                         ? FBAppEventsDialogOutcomeValue_Cancelled
                                                                         : FBAppEventsDialogOutcomeValue_Completed),
                                     @"num_friends_picked" : [NSNumber numberWithUnsignedInteger:self.selection.count]
                                     }
                          session:self.session];
}

@end
