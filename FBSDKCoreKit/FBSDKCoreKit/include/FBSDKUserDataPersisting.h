/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAppEventUserDataType.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_UserDataPersisting)
@protocol FBSDKUserDataPersisting

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

- (nullable NSString *)getUserData;

- (void)clearUserData;

- (void)setUserData:(nullable NSString *)data
            forType:(FBSDKAppEventUserDataType)type;

- (void)clearUserDataForType:(FBSDKAppEventUserDataType)type;

- (void)setEnabledRules:(NSArray<NSString *> *)rules;

- (nullable NSString *)getInternalHashedDataForType:(FBSDKAppEventUserDataType)type;

- (void)setInternalHashData:(nullable NSString *)hashData
                    forType:(FBSDKAppEventUserDataType)type;

@end

NS_ASSUME_NONNULL_END
