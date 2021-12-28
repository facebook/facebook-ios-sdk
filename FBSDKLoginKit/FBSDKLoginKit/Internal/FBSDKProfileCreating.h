/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

@class FBSDKLocation;
@class FBSDKProfile;
@class FBSDKUserAgeRange;
typedef NSString FBSDKUserIdentifier;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ProfileCreating)
@protocol FBSDKProfileCreating

// UNCRUSTIFY_FORMAT_OFF
- (FBSDKProfile *)createProfileWithUserID:(FBSDKUserIdentifier *)userID
                                firstName:(nullable NSString *)firstName
                               middleName:(nullable NSString *)middleName
                                 lastName:(nullable NSString *)lastName
                                     name:(nullable NSString *)name
                                  linkURL:(nullable NSURL *)linkURL
                              refreshDate:(nullable NSDate *)refreshDate
                                 imageURL:(nullable NSURL *)imageURL
                                    email:(nullable NSString *)email
                                friendIDs:(nullable NSArray<FBSDKUserIdentifier *> *)friendIDs
                                 birthday:(nullable NSDate *)birthday
                                 ageRange:(nullable FBSDKUserAgeRange *)ageRange
                                 hometown:(nullable FBSDKLocation *)hometown
                                 location:(nullable FBSDKLocation *)location
                                   gender:(nullable NSString *)gender
                                isLimited:(BOOL)isLimited
NS_SWIFT_NAME(createProfile(userID:firstName:middleName:lastName:name:linkURL:refreshDate:imageURL:email:friendIDs:birthday:ageRange:hometown:location:gender:isLimited:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
