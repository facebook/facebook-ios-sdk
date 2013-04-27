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

#import <Foundation/Foundation.h>
#import "FBCacheDescriptor.h"

/*
 @class 
 
 @abstract
 Represents the data needed by an FBFriendPickerViewController, in order to construct
 the necessary request to populate the view; instances of FBFriendPickerCacheDescriptor
 are used to fetch data ahead of the point when the data is used to populate a display.
 
 @discussion
 A common use of an FBFriendPickerCacheDescriptor instance, is to allocate an instance
 at the point when a session is opened, and then call prefetchAndCacheForSession. This 
 causes the API to fetch and cache the data needed by the FBFriendPickerViewController.
 If at some point the user goes to select friends, the FBFriendPickerViewController
 will first check the cache for a copy of the friends list, and then after displaying
 whatever cached data is available, then it will fetch a fresh copy of the friends list.
 
 @unsorted
 */
@interface FBFriendPickerCacheDescriptor : FBCacheDescriptor

/*
 @method
 
 @abstract
 Initializes an instance with default values for populating 
 a FBFriendPickerViewController, at some later point.
*/
- (id)init;

/*
 @method
 
 @abstract
 Initializes an instance specifying the userID to use for populating 
 a FBFriendPickerViewController, at some later point.
*/
- (id)initWithUserID:(NSString*)userID;

/*
 @method
 
 @abstract
 Initializes an instance specifying the fields to use for populating 
 a FBFriendPickerViewController, at some later point.
*/
- (id)initWithFieldsForRequest:(NSSet*)fieldsForRequest;

/*
 @method
 
 @abstract
 Initializes an instance specifying the userID and fields to use for populating 
 a FBFriendPickerViewController, at some later point.
  
 @param userID              fbid of the user whose friends we wish to display; nil='me'
 @param fieldsForRequest    set of additional fields to include in request for friends 
 */
- (id)initWithUserID:(NSString*)userID fieldsForRequest:(NSSet*)fieldsForRequest;

/*
 @abstract
 Fields to use when fetching data for the view
 */
@property (nonatomic, readonly, copy) NSSet *fieldsForRequest;

/*
 @abstract
 Indicates the fbid of the user whose friends are being viewed
 */
@property (nonatomic, readonly, copy) NSString *userID;

@end
