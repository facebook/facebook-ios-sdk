/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKProfileFactory.h"

#import "FBSDKLoginKit.h"

@implementation FBSDKProfileFactory

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
{
  return [[FBSDKProfile alloc] initWithUserID:userID
                                    firstName:firstName
                                   middleName:middleName
                                     lastName:lastName
                                         name:name
                                      linkURL:linkURL
                                  refreshDate:refreshDate
                                     imageURL:imageURL
                                        email:email
                                    friendIDs:friendIDs
                                     birthday:birthday
                                     ageRange:ageRange
                                     hometown:hometown
                                     location:location
                                       gender:gender
                                    isLimited:isLimited];
}

@end

#endif
