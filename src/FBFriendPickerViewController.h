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

#import <Foundation/Foundation.h>
#import "FBGraphUser.h"
#import "FBSession.h"

@protocol FBFriendPickerDelegate;

@interface FBFriendPickerViewController : UIViewController

@property (nonatomic) BOOL allowsMultipleSelection;
@property (nonatomic, assign) id<FBFriendPickerDelegate> delegate;
@property (nonatomic) BOOL includesPicture;
@property (nonatomic, copy) NSSet *propertiesForRequest;
@property (nonatomic, retain) FBSession *session;
@property (nonatomic, copy) NSString *userID;

// The list of people that are currently selected in the veiw.
// The items in the array are id<FBGraphUser>.
@property (nonatomic, retain, readonly) NSArray *selection;

- (id)init;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

// Starts a query against the server for a set of friends.  It is legal
// to call this more than once.
- (void)start;

// Updates the view locally without requerying data from the server.
// Use this if filter/sort properties change that would affect which
// people appear or what order they appear in.
- (void)updateView;

@end

// An optional protocol that enables deeper control of certain aspects
// of the view.
@protocol FBFriendPickerDelegate <NSObject>
@optional

// Called whenever the selection changes.
- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker;

// Called on each user to determine whether they show up in the list.
// This can be used to implement a search bar that filters the list.
- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id <FBGraphUser>)user;

// Called if there is a communication error.
- (void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                       handleError:(NSError *)error;

@end
