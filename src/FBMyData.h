/*
 * Copyright 2010 Facebook
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

@protocol FBMyDataDelegate;
@class FBMyData;

/*! 
 @typedef FBMyDataProperty enum
 
 @abstract Used to identify properties that can be fetched using `FBMyData`
 
 @discussion
 */
enum {
    /*! Represents the me property of `FBMyData` */
    FBMyDataPropertyMe                   = 1 << 0,
    
    /*! Represents the me property of `FBMyData` */
    FBMyDataPropertyFriends              = 1 << 1,
};
typedef unsigned long long  FBMyDataProperty;

/*! 
 @typedef
 
 @abstract Block type used to handle results from asynchronous `FBMyData` operations
 @discussion
 */
typedef void (^FBMyDataResultHandler)(FBMyData *myData,
                                      id result,
                                      NSError *error);

/*!
 @class FBMyData
 @abstract 
 The `FBMyData` class is a high-level class for acheiving common lightweight integration with Facebook. An instance
 of the `FBMyData` class interacts `FBSession.activeSession` to provide features such as simple data fetching, as
 well as helpers for interaction with UI such as a button to connect or login with Facebook. 
 
 `FBMyData` is built atop primitives in the SDK such as FBRequest, FBRequestConnection, and FBSession. Applications
 may freely mix and match use of `FBMyData` with use of the lower-level and more flexible components; with one
 restriction. Applications that use `FBMyData` must adopt the `FBSession.activeSession` model for managing sessions.
 */
@interface FBMyData : NSObject

/*!
 @abstract
 Makes available the user object for the current user. Upon construction of an `FBMyData` object, the me object is
 set to nil. Once the active session is open, `FBMyData` objects in the system will fetch the users' me
 object and populate this property with its contents. Applications my assign a delegate in order to get notified when
 `FBMyData` has updated this or any other data property on the object.
 
 Note, while you may explicitly request a fetch of `me`, the `me` property is also auto fetched for each instance 
 of `FBMyData`. Instances of `FBMyData` share a cache in order to avoid over-fetching properties.
 */
@property (retain, nonatomic, readonly) id<FBGraphUser> me;

/*!
 @abstract
 Makes available the friends list for the current user. Unlike uses of the `me` property, applications must first call
 `fetchProperties` in order to inform the `FBMyData` instance that a friends list is needed. Applications my assign a
 delegate in order to get notified when `FBMyData` has updated this or any other data property on the object.
 */
@property (retain, nonatomic, readonly) id friends;

/*!
 @abstract
 Enables an application to be notified of the presence or absence of a currently logged in user, as well as
 notifications of updates to data properties of the `FBMyData` instance. 
 */
@property (nonatomic, assign) id<FBMyDataDelegate> delegate;

/*!
 @abstract
 Initializes and returns an `FBMyData` object.  The underlying session has basic permissions granted to it.
 */
- (id)init;

/*!
 @method
 
 @abstract
 Initializes and returns an `FBMyData` object constructed with the specified permissions.
 
 @param permissions  An array of strings representing the permissions to request during the
 authentication flow. A value of nil will indicates basic permissions.
 */
- (id)initWithPermissions:(NSArray *)permissions;

/*!
 @method
 
 @abstract
 Informs `FBMyData` that an update to the specified property or properties is required. For `me` this causes
 a refresh, but for `friends` and other properties of the object, `fetchProperties` must be called at least once
 in order for the property to have a non-nil value.
 
 @param properties  An enumerated value specifying the property or properties to fetch.
 */
- (void)fetchProperties:(FBMyDataProperty)properties;

/*!
 @method
 
 @abstract
 Posts a status update for the user, and optionally completes with the id of the status.
 
 @param message     The message to be published to the users feed
 */
- (void)postStatusUpdate:(NSString *)message 
       completionHandler:(FBMyDataResultHandler)handler;

/*!
 @method
 
 @abstract
 Posts a status update for the user, and optionally completes with the id of the status.
 
 @param message     The message to be published to the users feed
 @param place       The place associated with the status update, the place parameter may be an fbid as an NSString
                    or NSNumber, or place may be a graph object with an id property representing the desired place.
                    Note, place, tags, and handler may be nil, but if tags are specified a place must be specified.
 @param tags        An NSArray, NSSet or other enumerable object, whose elements represent the users to tag in the
                    post. Each element may be an FBID as an NSString or NSNumber, or a graph object representing a
                    user. Note: if tags are present, place must be non-nil. 
 @param handler     The optional handler to handle the post completion and recieve the id or error for the status.
 */
- (void)postStatusUpdate:(NSString *)message
                   place:(id)place
                    tags:(id<NSFastEnumeration>)tags
       completionHandler:(FBMyDataResultHandler)handler;

/*!
 @method
 
 @abstract
 Posts a photo and optional title, and completes with the id of the photo.
 
 @param image       The image to post.
 @param name        The optional name of the image.
 @param handler     The optional handler to handle the post completion and recieve the id or error for the photo.
 */
- (void)postPhoto:(UIImage *)image
             name:(NSString *)name
completionHandler:(FBMyDataResultHandler)handler;

/*!
 @method
 
 @abstract
 Handles a UI operation, such as a button press or menu selection, to connect the application to a current Facebook
 user for the active session. This method and its connecting counterpart are meant to enable very simple
 implementation of UI to login or connect, and subsequently disconnect from facebook within an application.
 */
- (void)handleLoginPressed;

/*!
 @method
 
 @abstract
 Handles a UI operation, such as a button press or menu selection, to disconnect the current Facebook user from 
 the application's active session. This method and its connecting counterpart are meant to enable very simple
 implementation of UI to login or connect, and subsequently disconnect from facebook within an application.
 */
- (void)handleLogoutPressed;

@end

/*!
 @protocol 
 
 @abstract
 The `FBMyDataDelegate` protocol defines the methods used to receive event 
 notifications from `FBMyData` objects.
 */
@protocol FBMyDataDelegate <NSObject>

@optional

/*!
 @abstract
 Notifies the application that the active session is open and represents a user that is
 currently connected with Facebook. This notification can be used to drive UI such as the presence
 of features that only work when a user of an application is connected with Facebook.
 */
- (void)myDataHasLoggedInUser:(FBMyData *)myData;

/*!
 @abstract
 Notifies the application that a property of `FBMyData` has been fetched or updated. If multiple properties are
 updated, `myDataFetched:property` will be called multiple times; the property argument will only represent a 
 single fetched property per call.
 */
- (void)myDataFetched:(FBMyData *)myData
             property:(FBMyDataProperty)property;

/*!
 @abstract
 Notifies the application that the active session is closed and does not represent an active connection with Facebook.
 This notification can be used to drive UI such as the removal or disabling of features that only work when a user
 of an application is connected with Facebook.
 */
- (void)myDataHasLoggedOutUser:(FBMyData *)myData;

@end

