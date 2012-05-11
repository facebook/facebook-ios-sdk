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

@protocol FBPlacesPickerDelegate;

@interface FBPlacesPickerViewController : UIViewController

@property (nonatomic, retain) IBOutlet UITextField *searchTextField;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, assign) id<FBPlacesPickerDelegate> delegate;
@property (nonatomic, copy) NSSet *fieldsForRequest;
@property (nonatomic) BOOL itemPicturesEnabled;
@property (nonatomic) CLLocationCoordinate2D locationCoordinate;
@property (nonatomic) NSInteger radiusInMeters;
@property (nonatomic) NSInteger resultsLimit;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic) BOOL searchTextEnabled;
@property (nonatomic, retain) FBSession *session;

// The place that is currently selected in the view.  This is nil
// if nothing is selected.
@property (nonatomic, retain, readonly) id<FBGraphPlace> selection;

- (id)init;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (void)loadData;

@end

@protocol FBPlacesPickerDelegate <NSObject>
@optional

// Called whenever the selection changes.
- (void)placesPickerViewControllerSelectionDidChange:
(FBPlacesPickerViewController *)placesPicker;

// Called on each user to determine whether they show up in the list.
// This can be used to implement a search bar that filters the list.
- (BOOL)placesPickerViewController:(FBPlacesPickerViewController *)placesPicker
                shouldIncludePlace:(id <FBGraphPlace>)place;

// Called if there is a communication error.
- (void)placesPickerViewController:(FBPlacesPickerViewController *)placesPicker
                       handleError:(NSError *)error;

@end
