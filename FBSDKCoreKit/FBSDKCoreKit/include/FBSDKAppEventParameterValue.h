/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/*
 @methodgroup Predefined values to assign to event parameters that accompany events logged through the `logEvent` family
 of methods on `FBSDKAppEvents`.  Common event parameters are provided in the `FBSDKAppEventParameterName*` constants.
 */

/// typedef for FBSDKAppEventParameterValue
typedef NSString *const FBSDKAppEventParameterValue NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(AppEvents.ParameterValue);

/// Yes-valued parameter value to be used with parameter keys that need a Yes/No value
FOUNDATION_EXPORT FBSDKAppEventParameterValue FBSDKAppEventParameterValueYes;

/// No-valued parameter value to be used with parameter keys that need a Yes/No value
FOUNDATION_EXPORT FBSDKAppEventParameterValue FBSDKAppEventParameterValueNo;
