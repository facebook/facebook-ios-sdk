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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "FBGraphPlace.h"
#import "FBSession.h"

@protocol FBPlacePickerDelegate;

/*!
 @class FBPlacePickerViewController
 
 @abstract
 FBPlacePickerViewController object is used to create and coordinate UI
 for viewing and picking places.
 
 @unsorted
 */
@interface FBPlacePickerViewController : UIViewController

/*!
 @abstract
 Outlet for the spinner object used by the view controller
 */
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

/*!
 @abstract
 Outlet for the tableView object used by the view controller
 */
@property (nonatomic, retain) IBOutlet UITableView *tableView;

/*!
 @abstract
 Delegate used by the view controller to notify of selection changes, and handle
 errors and filtering.
 */
@property (nonatomic, assign) id<FBPlacePickerDelegate> delegate;

/*!
 @abstract
 Set of fields which should be requested by the view controler for use either in display or filtering
 */
@property (nonatomic, copy) NSSet *fieldsForRequest;

/*!
 @abstract
 Indicates whether items pictures should be fetched and displayed
 */
@property (nonatomic) BOOL itemPicturesEnabled;

/*!
 @abstract
 Sets the coordinates to use for place discovery
 */
@property (nonatomic) CLLocationCoordinate2D locationCoordinate;

/*!
 @abstract
 Sets the radius to use for place discovery
 */
@property (nonatomic) NSInteger radiusInMeters;

/*!
 @abstract
 Maximum number of places to fetch
 */
@property (nonatomic) NSInteger resultsLimit;

/*!
 @abstract
 Search words used to narrow results returned
 */
@property (nonatomic, copy) NSString *searchText;

/*!
 @abstract
 User session
 */
@property (nonatomic, retain) FBSession *session;

/*!
 @abstract
 The place that is currently selected in the view.  This is nil
 if nothing is selected.
  */
@property (nonatomic, retain, readonly) id<FBGraphPlace> selection;

/*!
 @abstract
 Initializes an instance of the view controller
 */
- (id)init;

/*!
 @abstract
 Initializes an instance of the view controller
 */
- (id)initWithCoder:(NSCoder *)aDecoder;

/*!
 @abstract
 Initializes an instance of the view controller
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

/*!
 @abstract
 Causes the view controller to fetch data, either initialler, or in order to update the view
 as a result of changes to search criteria, filter, location, etc.
 */
- (void)loadData;

@end

/*!
 @abstract
 If a conforming delegate is provided, the view controller will notify the delegate of selection change,
 filter and error events
 */
@protocol FBPlacePickerDelegate <NSObject>
@optional

/*!
 @abstract
 Called whenever data is loaded.

 @discussion
 The tableView is automatically reloaded when this happens, but if
 another tableView (such as for a UISearchBar) is showing data then
 it may need to be reloaded too.
 
 @param placePicker   the view controller object sending the notification
 */
- (void)placePickerViewControllerDataDidChange:
(FBPlacePickerViewController *)placePicker;

/*!
 @abstract
 Called whenever the selection changes.
 @discussion
 The tableView is automatically reloaded when this happens, but if
 another tableView (such as for a UISearchBar) is showing data then
 it may need to be reloaded too.
 
 @param placePicker   the view controller object sending the notification
 */
- (void)placePickerViewControllerSelectionDidChange:
(FBPlacePickerViewController *)placePicker;

/*!
 @abstract
 Called on each user to determine whether they show up in the list.
  
 @discussion
 This can be used to implement a search bar that filters the list.
 */
- (BOOL)placePickerViewController:(FBPlacePickerViewController *)placePicker
                shouldIncludePlace:(id <FBGraphPlace>)place;

/*!
 @abstract
 Called if there is a communication error.
 */
- (void)placePickerViewController:(FBPlacePickerViewController *)placePicker
                       handleError:(NSError *)error;

@end
