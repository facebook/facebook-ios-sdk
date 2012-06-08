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
#import "FBGraphUser.h"
#import "FBSession.h"
#import "FBCacheDescriptor.h"

@protocol FBFriendPickerDelegate;
@class FBFriendPickerCacheDescriptor;

/*! 
 @typedef FBFriendSortOrdering enum
 
 @abstract Indicates the order in which friends should be listed in the friend picker.
 
 @discussion
 */
typedef enum {
    /*! Sort friends by first, middle, last names. */
    FBFriendSortByFirstName,
    /*! Sort friends by last, first, middle names. */
    FBFriendSortByLastName
} FBFriendSortOrdering;

/*! 
 @typedef FBFriendDisplayOrdering enum
 
 @abstract Indicates whether friends should be displayed first-name-first or last-name-first.
 
 @discussion
 */
typedef enum {
    /*! Display friends as First Middle Last. */
    FBFriendDisplayByFirstName,
    /*! Display friends as Last First Middle. */
    FBFriendDisplayByLastName,
} FBFriendDisplayOrdering;


/*! 
 @class
 
 @abstract 
 FBFriendPickerViewController object is used to create and coordinate UI
 for viewing and selecting friends.
 */
@interface FBFriendPickerViewController : UIViewController

/*!
 @abstract
 Outlet for the spinner object used by the view controller
 */
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

/*!
 @abstract
 Outlet for the tableView used by the view controller
 */
@property (nonatomic, retain) IBOutlet UITableView *tableView;

/*!
 @abstract
 specifies whether multi-selelect is enabled
 */
@property (nonatomic) BOOL allowsMultipleSelection;

/*!
 @abstract
 Optional delegate
 */
@property (nonatomic, assign) id<FBFriendPickerDelegate> delegate;

/*!
 @abstract
 Indicates whether pictures are enabled for the items
 */
@property (nonatomic) BOOL itemPicturesEnabled;

/*!
 @abstract
 Fields to use when fetching data for the view
 */
@property (nonatomic, copy) NSSet *fieldsForRequest;

/*!
 @abstract
 Indicates the session to use with the view
 */
@property (nonatomic, retain) FBSession *session;

/*!
 @abstract
 Indicates the fbid of the user whose friends are being viewed
 */
@property (nonatomic, copy) NSString *userID;

/*!
 @abstract
 The list of people that are currently selected in the veiw.
 The items in the array are id<FBGraphUser>.
 */
@property (nonatomic, retain, readonly) NSArray *selection;

/*!
 @abstract
 The order in which friends are sorted in the display.
 */
@property (nonatomic) FBFriendSortOrdering sortOrdering;

/*!
 @abstract
 The order in which friends' names are constructed.
 */
@property (nonatomic) FBFriendDisplayOrdering displayOrdering;

/*!
 @abstract
 Used to initialize the object
 */
- (id)init;

/*!
 @abstract
 Used to initialize the object

 @param aDecoder        See [UIViewController initWithCoder:].
 */
- (id)initWithCoder:(NSCoder *)aDecoder;

/*!
 @abstract
 Used to initialize the object
 
 @param nibNameOrNil            See [UIViewController initWithNibName:bundle:].
 @param nibBundleOrNil          See [UIViewController initWithNibName:bundle:].
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

/*!
 @abstract
 Configures the properties that impact any queries made by the view controller, using a cacheDescriptor
 
 @discussion
 Cache descriptors are used to fetch and cache the data used by the ViewController, at some point
 prior in the execution of the application. If the ViewController finds a cached copy of the data, it will
 first display the cached content, and then fetch a fresh copy from the server.
 
 @param cacheDescriptor     an <FBCacheDescriptor> to pull properties from
 */
- (void)configureUsingCachedDescriptor:(FBCacheDescriptor*)cacheDescriptor;

/*!
 @abstract
 Starts a query against the server for a set of friends.  It is legal
 to call this more than once.
 */
- (void)loadData;

/*!
 @abstract
 Updates the view locally without requerying data from the server.
 
 @discussion
 Use this if filter/sort properties change that would affect which
 people appear or what order they appear in.
 */
- (void)updateView;

/*!
 @method
 
 @abstract
 Creates a cache descriptor based on default settings of FBFriendPickerViewController
 
 @discussion
 A cacheDescriptor object may be used to fetch data ahead of use by the FBFriendPickerViewController, and
 may also be used to configure a FBFriendPickerViewController object at time of use
 */
+ (FBCacheDescriptor*)cacheDescriptor;

/*!
 @method

 @param userID              fbid of the user whose friends we wish to display; nil='me'
 @param fieldsForRequest    set of additional fields to include in request for friends 
 
 @abstract
 Creates a cache descriptor with additional fields and a userID for use with FBFriendPickerViewController
 
 @discussion
 A cacheDescriptor object may be used to fetch data ahead of use by the FBFriendPickerViewController, and
 may also be used to configure a FBFriendPickerViewController object at time of use
 
 */
+ (FBCacheDescriptor*)cacheDescriptorWithUserID:(NSString*)userID fieldsForRequest:(NSSet*)fieldsForRequest;

@end

/*! 
 @protocol
 
 @abstract 
 Used by the FBFriendPickerViewController to (optionally) notify clients of events and allow for
 deeper control of the view
 */
@protocol FBFriendPickerDelegate <NSObject>
@optional

/*!
 @abstract 
 Called whenever data is loaded.

 @discussion
 The tableView is automatically reloaded when this happens, but if
 another tableView (such as for a UISearchBar) is showing data then
 it may need to be reloaded too.

 @param friendPicker        the friend picker whose data changed
 */
- (void)friendPickerViewControllerDataDidChange:(FBFriendPickerViewController *)friendPicker;

/*!
 @abstract
 Called whenever the selection changes.

 @param friendPicker        the friend picker whose selection changed
 */
- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker;

/*!
 @abstract
 Called on each user to determine whether they show up in the list.
 
 @discussion
 This can be used to implement a search bar that filters the list.

 @param friendPicker        the friend picker that is asking whether to display a user
 @param user                an <FBGraphUser> object representing the user to show (or not)
 */
- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id <FBGraphUser>)user;

/*!
 @abstract
 Called if there is a communication error.

 @param friendPicker        the friend picker that encountered the error
 @param error               the error that occurred
 */
- (void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                       handleError:(NSError *)error;

@end
