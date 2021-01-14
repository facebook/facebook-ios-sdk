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

NS_SWIFT_NAME(FBPermission)
@interface FBSDKPermission : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 The raw string representation of the permission
*/
@property (nonatomic, readonly, copy) NSString *value;

/**
 Attempts to initialize a new permission with the given string.
 Creation will fail and return nil if the string is invalid.

 @param string the raw permission string
*/
- (nullable instancetype)initWithString:(NSString *)string;

/**
 Returns a set of FBSDKPermission from a set of raw permissions strings.
 Will return nil if any of the input permissions is invalid.
*/
+ (nullable NSSet<FBSDKPermission *> *)permissionsFromRawPermissions:(NSSet<NSString *> *)rawPermissions;

/**
 Returns a set of string permissions from a set of FBSDKPermission by
 extracting the "value" property for each element.
*/
+ (NSSet<NSString *> *)rawPermissionsFromPermissions:(NSSet<FBSDKPermission *> *)permissions;

@end

NS_ASSUME_NONNULL_END
