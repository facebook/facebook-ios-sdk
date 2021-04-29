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

#import "TargetConditionals.h"

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
