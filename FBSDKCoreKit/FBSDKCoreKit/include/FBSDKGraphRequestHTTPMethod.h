/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/// typedef for FBSDKHTTPMethod
typedef NSString *const FBSDKHTTPMethod NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(HTTPMethod);

/// GET Request
FOUNDATION_EXPORT FBSDKHTTPMethod FBSDKHTTPMethodGET NS_SWIFT_NAME(get);

/// POST Request
FOUNDATION_EXPORT FBSDKHTTPMethod FBSDKHTTPMethodPOST NS_SWIFT_NAME(post);

/// DELETE Request
FOUNDATION_EXPORT FBSDKHTTPMethod FBSDKHTTPMethodDELETE NS_SWIFT_NAME(delete);
