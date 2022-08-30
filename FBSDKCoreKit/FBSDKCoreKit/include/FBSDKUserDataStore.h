/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAppEvents.h>
#import <FBSDKCoreKit/FBSDKAppEventUserDataType.h>
#import <FBSDKCoreKit/FBSDKUserDataPersisting.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_UserDataStore)
@interface FBSDKUserDataStore : NSObject <FBSDKUserDataPersisting>

/*
  Sets custom user data to associate with all app events. All user data are hashed
  and used to match Facebook user from this instance of an application.

  The user data will be persisted between application instances.

 @param email user's email
 @param firstName user's first name
 @param lastName user's last name
 @param phone user's phone
 @param dateOfBirth user's date of birth
 @param gender user's gender
 @param city user's city
 @param state user's state
 @param zip user's zip
 @param country user's country
 @param externalId user's external id
 */
// UNCRUSTIFY_FORMAT_OFF
- (void)setUserEmail:(nullable NSString *)email
           firstName:(nullable NSString *)firstName
            lastName:(nullable NSString *)lastName
               phone:(nullable NSString *)phone
         dateOfBirth:(nullable NSString *)dateOfBirth
              gender:(nullable NSString *)gender
                city:(nullable NSString *)city
               state:(nullable NSString *)state
                 zip:(nullable NSString *)zip
             country:(nullable NSString *)country
          externalId:(nullable NSString *)externalId
NS_SWIFT_NAME(setUser(email:firstName:lastName:phone:dateOfBirth:gender:city:state:zip:country:externalId:));
// UNCRUSTIFY_FORMAT_ON

/*
  Returns the set user data else nil
 */
- (nullable NSString *)getUserData;

/*
  Clears the current user data
 */
- (void)clearUserData;

/*
 Sets custom user data to associate with all app events. All user data are hashed
 and used to match Facebook user from this instance of an application.

 The user data will be persisted between application instances.

 @param data  data
 @param type  data type, e.g. FBSDKAppEventEmail, FBSDKAppEventPhone
 */
- (void)setUserData:(nullable NSString *)data
            forType:(FBSDKAppEventUserDataType)type;

/*
 Clears the current user data of certain type
 */
- (void)clearUserDataForType:(FBSDKAppEventUserDataType)type;

@end

NS_ASSUME_NONNULL_END
