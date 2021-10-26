/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKTVOSKit/FBSDKDeviceLoginViewController.h>
#import <TVMLKit/TVViewElement.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract Represents a '<FBSDKDeviceLoginViewController />' tag in TVML
 @discussion The tag should be part of a document that is
 presented modally. For example,

 <code>
 var createLogin = function() {
 var s = `<?xml version="1.0" encoding="UTF-8" ?>
 <document>
 <FBSDKLoginViewController publishPermissions="publish_actions" />
 </document>`
 return new DOMParser().parseFromString(s, "application/xml");
 }

 // in your code
 navigationDocument.presentModal(createLogin());
 </code>

 The '<FBSDKDeviceLoginViewController />' tag can also have the following attributes:
 - either a `readPermissions` or (not both) `publishPermissions` attribute whose value is a comma delimited
 list of permissions to request.
 - `redirectURL` an optional URL to redirect the user to after completing the login.

 This element can dispatch the following events to Javascript, which map to corresponding
 messages of `FBSDKDeviceLoginViewControllerDelegate`.
 - `onFacebookLoginViewControllerFinish`
 - `onFacebookLoginViewControllerCancel`
 - `onFacebookLoginViewControllerError`

 These events can bubble up the DOM.
 */

NS_SWIFT_NAME(FBTVLoginViewControllerElement)
@interface FBSDKTVLoginViewControllerElement : TVViewElement <FBSDKDeviceLoginViewControllerDelegate>

@end

NS_ASSUME_NONNULL_END
