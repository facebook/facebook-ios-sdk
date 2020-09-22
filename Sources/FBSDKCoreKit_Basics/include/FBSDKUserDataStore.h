// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// typedef for FBSDKAppEventUserDataType
typedef NSString *const FBSDKAppEventUserDataType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(AppEvents.UserDataType);

/** Parameter key used to specify user's email. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventEmail;
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventEmail;

/** Parameter key used to specify user's first name. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventFirstName;

/** Parameter key used to specify user's last name. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventLastName;

/** Parameter key used to specify user's phone. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventPhone;

/** Parameter key used to specify user's date of birth. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventDateOfBirth;

/** Parameter key used to specify user's gender. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventGender;

/** Parameter key used to specify user's city. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventCity;

/** Parameter key used to specify user's state. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventState;

/** Parameter key used to specify user's zip. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventZip;

/** Parameter key used to specify user's country. */
FOUNDATION_EXPORT FBSDKAppEventUserDataType FBSDKAppEventCountry;

NS_SWIFT_NAME(UserDataStore)
@interface FBSDKUserDataStore : NSObject

+ (void)setAndHashUserEmail:(nullable NSString *)email
                  firstName:(nullable NSString *)firstName
                   lastName:(nullable NSString *)lastName
                      phone:(nullable NSString *)phone
                dateOfBirth:(nullable NSString *)dateOfBirth
                     gender:(nullable NSString *)gender
                       city:(nullable NSString *)city
                      state:(nullable NSString *)state
                        zip:(nullable NSString *)zip
                    country:(nullable NSString *)country;
+ (void)setAndHashData:(nullable NSString *)data
               forType:(FBSDKAppEventUserDataType)type;
+ (void)setInternalHashData:(nullable NSString *)hashData
                    forType:(FBSDKAppEventUserDataType)type;
+ (void)setEnabledRules:(NSArray<NSString *> *)rules;
+ (nullable NSString *)getHashedData;
+ (nullable NSString *)getInternalHashedDataForType:(FBSDKAppEventUserDataType)type;
+ (void)clearDataForType:(FBSDKAppEventUserDataType)type;

@end

NS_ASSUME_NONNULL_END
