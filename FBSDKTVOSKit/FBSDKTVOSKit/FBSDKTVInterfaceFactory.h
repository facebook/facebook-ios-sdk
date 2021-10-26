/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <TVMLKit/TVInterfaceFactory.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract An implementation of `TVInterfaceCreating` for using FBSDKTVOSKit elements in TVML apps.
 @discussion You should assign an instance of this factory prior to the construction
  of your `TVApplicationController`. For example,
 <code>
 TVInterfaceFactory.sharedInterfaceFactory().extendedInterfaceCreator = FBSDKTVInterfaceFactory()
 </code>

 If you have your own `TVInterfaceCreating` implementation, use `initWithTVInterfaceCreating:`.

 This class will also register Facebook `TVViewElement` subclasses to the `TVElementFactory`.
 This extends TVML with the following tags:

 * `<FBSDKLoginButton />` (see FBSDKTVLoginButtonElement.h for details)
 * `<FBSDKLoginViewController />` (see FBSDKTVLoginViewControllerElement.h for details)

 */
NS_SWIFT_NAME(TVInterfaceFactory)
@interface FBSDKTVInterfaceFactory : NSObject <TVInterfaceCreating>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/*!
 @abstract The designated initializer which can chain a `<TVInterfaceCreating>` implementation.
 */
- (instancetype)initWithInterfaceCreator:(nullable id<TVInterfaceCreating>)interfaceCreator
  NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
