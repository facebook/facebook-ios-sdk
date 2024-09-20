/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

typedef NSString *const FBSDKAppEventUserDataType NS_TYPED_EXTENSIBLE_ENUM;

/// Parameter key used to specify user's email.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventEmail;

/// Parameter key used to specify user's first name.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventFirstName;

/// Parameter key used to specify user's last name.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventLastName;

/// Parameter key used to specify user's phone.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventPhone;

/// Parameter key used to specify user's date of birth.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventDateOfBirth;

/// Parameter key used to specify user's gender.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventGender;

/// Parameter key used to specify user's city.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventCity;

/// Parameter key used to specify user's state.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventState;

/// Parameter key used to specify user's zip.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventZip;

/// Parameter key used to specify user's country.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventCountry;

/// Parameter key used to specify user's external id.
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventExternalId;
