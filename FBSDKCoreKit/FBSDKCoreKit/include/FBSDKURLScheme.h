/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

typedef NSString *FBSDKURLScheme NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(URLSchemeEnum);

FOUNDATION_EXPORT FBSDKURLScheme const FBSDKURLSchemeFacebookAPI NS_SWIFT_NAME(facebookAPI);
FOUNDATION_EXPORT FBSDKURLScheme const FBSDKURLSchemeMessengerApp NS_SWIFT_NAME(messengerApp);
FOUNDATION_EXPORT FBSDKURLScheme const FBSDKURLSchemeFacebookAuth NS_SWIFT_NAME(facebookAuth);
FOUNDATION_EXPORT FBSDKURLScheme const FBSDKURLSchemeHTTPS NS_SWIFT_NAME(https);
FOUNDATION_EXPORT FBSDKURLScheme const FBSDKURLSchemeHTTP NS_SWIFT_NAME(http);
FOUNDATION_EXPORT FBSDKURLScheme const FBSDKURLSchemeWeb NS_SWIFT_NAME(web);
