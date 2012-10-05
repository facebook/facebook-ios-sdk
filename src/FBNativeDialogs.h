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

@class FBSession;

/*!
 @typedef FBNativeDialogResult enum
 
 @abstract
 Passed to a handler to indicate the result of a dialog being displayed to the user.
*/
typedef enum {
    /*! Indicates that the dialog action completed successfully. */
    FBNativeDialogResultSucceeded,
    /*! Indicates that the dialog action was cancelled (either by the user or the system). */
    FBNativeDialogResultCancelled,
    /*! Indicates that the dialog could not be shown (because not on ios6 or ios6 auth was not used). */
    FBNativeDialogResultError
} FBNativeDialogResult;

/*!
 @typedef
 
 @abstract Defines a handler that will be called in response to the native share dialog
 being displayed.
 */
typedef void (^FBShareDialogHandler)(FBNativeDialogResult result, NSError *error);

/*!
 @class FBNativeDialogs
 
 @abstract
 Provides methods to display native (i.e., non-Web-based) dialogs to the user.
 Currently the iOS 6 sharing dialog is supported.
*/ 
@interface FBNativeDialogs : NSObject

/*!
 @abstract
 Presents a dialog that allows the user to share a status update that may include
 text, images, or URLs. This dialog is only available on iOS 6.0 and above. The
 current active session returned by [FBSession activeSession] will be used to determine
 whether the dialog will be displayed. If a session is active, it must be open and the
 login method used to authenticate the user must be native iOS 6.0 authentication.
 If no session active, then whether the call succeeds or not will depend on
 whether Facebook integration has been configured.
 
 @param viewController  The view controller which will present the dialog.
 
 @param initialText The text which will initially be populated in the dialog. The user
 will have the opportunity to edit this text before posting it. May be nil.
 
 @param image  A UIImage that will be attached to the status update. May be nil.
 
 @param url    An NSURL that will be attached to the status update. May be nil.
 
 @param handler A handler that will be called when the dialog is dismissed, or if an error
 occurs. May be nil.
 
 @return YES if the dialog was presented, NO if not (in the case of a NO result, the handler
 will still be called, with an error indicating the reason the dialog was not displayed)
 */
+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                                image:(UIImage*)image
                                  url:(NSURL*)url
                              handler:(FBShareDialogHandler)handler;

/*!
 @abstract
 Presents a dialog that allows the user to share a status update that may include
 text, images, or URLs. This dialog is only available on iOS 6.0 and above. The
 current active session returned by [FBSession activeSession] will be used to determine
 whether the dialog will be displayed. If a session is active, it must be open and the
 login method used to authenticate the user must be native iOS 6.0 authentication. 
 If no session active, then whether the call succeeds or not will depend on
 whether Facebook integration has been configured.
 
 @param viewController  The view controller which will present the dialog.
 
 @param initialText The text which will initially be populated in the dialog. The user
 will have the opportunity to edit this text before posting it. May be nil.
 
 @param images  An array of UIImages that will be attached to the status update. May
 be nil.
 
 @param urls    An array of NSURLs that will be attached to the status update. May be nil.
 
 @param handler A handler that will be called when the dialog is dismissed, or if an error
 occurs. May be nil.
 
 @return YES if the dialog was presented, NO if not (in the case of a NO result, the handler
 will still be called, with an error indicating the reason the dialog was not displayed)
 */
+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler;

/*!
 @abstract
 Presents a dialog that allows the user to share a status update that may include
 text, images, or URLs. This dialog is only available on iOS 6.0 and above. An
 <FBSession> may be specified, or nil may be passed to indicate that the current
 active session should be used. If a session is specified (whether explicitly or by
 virtue of being the active session), it must be open and the login method used to
 authenticate the user must be native iOS 6.0 authentication. If no session is specified
 (and there is no active session), then whether the call succeeds or not will depend on
 whether Facebook integration has been configured.
 
 @param viewController  The view controller which will present the dialog.
 
 @param session     The <FBSession> to use to determine whether or not the user has been
 authenticated with iOS native authentication. If nil, then [FBSession activeSession]
 will be checked. See discussion above for the implications of nil or non-nil session.
 
 @param initialText The text which will initially be populated in the dialog. The user
 will have the opportunity to edit this text before posting it. May be nil.
 
 @param images  An array of UIImages that will be attached to the status update. May
 be nil.
 
 @param urls    An array of NSURLs that will be attached to the status update. May be nil.
 
 @param handler A handler that will be called when the dialog is dismissed, or if an error
 occurs. May be nil.
 
 @return YES if the dialog was presented, NO if not (in the case of a NO result, the handler
 will still be called, with an error indicating the reason the dialog was not displayed)
 */
+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                              session:(FBSession*)session
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler;

/*!
 @abstract
 Determines whether a call to presentShareDialogModallyFrom: will successfully present
 a dialog. This is useful for applications that need to modify the available UI controls
 depending on whether the dialog is available on the current platform and for the current
 user.
 
 @param session     The <FBSession> to use to determine whether or not the user has been
 authenticated with iOS native authentication. If nil, then [FBSession activeSession]
 will be checked. See discussion above for the implications of nil or non-nil session.
 
 @return YES if the dialog would be presented for the session, and NO if not
 */
+ (BOOL)canPresentShareDialogWithSession:(FBSession*)session;

@end
