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
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."

#import "TargetConditionals.h"

#if !TARGET_OS_TV

@class FBSDKProfile;
@class FBSDKUserAgeRange;
typedef NSString FBSDKUserIdentifier;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ProfileProviding)
@protocol FBSDKProfileProviding

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
                                isLimited:(BOOL)isLimited
NS_SWIFT_NAME(createProfile(userID:firstName:middleName:lastName:name:linkURL:refreshDate:imageURL:email:friendIDs:birthday:ageRange:isLimited:));

@end

NS_ASSUME_NONNULL_END

#endif
