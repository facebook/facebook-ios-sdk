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

#import "FBGraphObjectPagingLoader.h"
#import "FBGraphObjectPickerViewController.h"

@class FBGraphObjectTableDataSource;
@class FBGraphObjectTableSelection;

@interface FBGraphObjectPickerViewController ()

+ (FBGraphObjectPagingMode)graphObjectPagingMode;
+ (NSTimeInterval)cacheRefreshDelay;
+ (NSString *)firstRenderLogString;

- (FBGraphObjectTableDataSource *)dataSource;
- (FBGraphObjectTableSelection *)selectionManager;
- (FBGraphObjectPagingLoader *)loader;

/*!
 @abstract
 Not all FBGraphObjectPickerViewController subclasses support multiple selection, but
 there is a shared implementation for those that do.
 */
@property (nonatomic) BOOL allowsMultipleSelection;

/*!
 @abstract
 Subclasses may override this method to implement request throttling. The default
 implementation simply calls -loadDataSkippingRoundTripIfCached:.
 */
- (void)loadDataThrottledSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached;

/*!
 @abstract
 This method must be overridden for loading the <FBRequest> to retrieve the subclass's
 graph objects. Do not call super.
 */
- (void)loadDataSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached;

/*!
 @abstract
 Provides subclasses with the opportunity to configure the data source with the view
 controller-specific presentation options.
 */
- (void)configureDataSource:(FBGraphObjectTableDataSource *)dataSource;

// The following methods help maintain source compatibility with existing code bases
// that use the FBFriendPickerDelegate or FBPlacePickerDelegate. Overrides must first
// call super then call the appropriate subclass delegate method, if it's implemented.

- (void)notifyDelegateDataDidChange;
- (void)notifyDelegateSelectionDidChange;
- (void)notifyDelegateOfError:(NSError *)error;

// Base class returns YES if the method is not implemented on the delegate.
- (BOOL)delegateIncludesGraphObject:(id<FBGraphObject>)graphObject;

@end
