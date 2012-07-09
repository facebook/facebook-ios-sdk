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

@protocol FBLoginViewDelegate;

/*! 
 @typedef FBLoginViewLoggedInDisplayStyle enum
 
 @abstract 
 Type used to specify the display style of the button.
 
 @discussion
 */
typedef enum {
    /*! Small square profile image and facebook icon overlayed */
    FBLoginViewStyleSquareSmall     = 0,
    
    /*! Large square profile image and facebook icon overlayed */
    FBLoginViewStyleSquareLarge     = 1,
    
    /*! Facebook image and profile image side-by-side */
    FBLoginViewStyleHorizontal      = 2,
        
} FBLoginViewStyle;

/*!
 @class
 @abstract
 */
@interface FBLoginView : UIView

/*!
 @abstract
 The display style for the login view.
 */
@property (nonatomic) FBLoginViewStyle style;

/*!
 @abstract
 The permissions to login with.  Defaults to nil, meaning basic permissions.@property (readwrite, copy)   NSArray *permissions;

 */
@property (readwrite, copy) NSArray *permissions;


/*!
 @abstract
 Initializes and returns an `FBLoginView` object.  The underlying session has basic permissions granted to it.
 */
- (id)init;

/*!
 @method
 
 @abstract
 Initializes and returns an `FBLoginView` object constructed with the specified permissions.
 
 @param permissions  An array of strings representing the permissions to request during the
 authentication flow. A value of nil will indicates basic permissions. 
 
 */
- (id)initWithPermissions:(NSArray *)permissions;

/*!
 @abstract
 The delegate object that receives updates for selection and display control.
 */
@property (nonatomic, assign) id<FBLoginViewDelegate> delegate;

@end

/*!
 @protocol 
 
 @abstract
 The `FBLoginViewDelegate` protocol defines the methods used to receive event 
 notifications from `FBLoginView` objects.
 */
@protocol FBLoginViewDelegate <NSObject>

@optional

/*!
 @abstract
 Tells the delegate that the view is now in logged in mode
 
 @param loginView   The login view that transitioned its view mode
 */
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView;

/*!
 @abstract
 Tells the delegate that the view is has now fetched user info

 @param loginView   The login view that transitioned its view mode
 
 @param user        The user info object describing the logged in user
 */
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user;

/*!
 @abstract
 Tells the delegate that the view is now in logged out mode
 
 @param loginView   The login view that transitioned its view mode
 */
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView;

@end

