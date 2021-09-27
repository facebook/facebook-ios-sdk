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

#import "FBSDKShareLinkContent.h"
#import "FBSDKShareMediaContent.h"
#import "FBSDKSharePhotoContent.h"
#import "FBSDKShareUtilityProtocol.h"
#import "FBSDKShareVideoContent.h"
#import "FBSDKSharingContent.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ShareUtility)
@interface FBSDKShareUtility : NSObject <FBSDKShareUtility>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (void)assertCollection:(id<NSFastEnumeration>)collection ofClass:itemClass name:(NSString *)name;
+ (void)assertCollection:(id<NSFastEnumeration>)collection ofClassStrings:(NSArray *)classStrings name:(NSString *)name;
+ (nullable NSString *)buildWebShareTags:(nullable NSArray<NSString *> *)peopleIDs;
+ (nullable NSDictionary<NSString *, id> *)convertPhoto:(nullable FBSDKSharePhoto *)photo;
+ (nullable UIImage *)imageWithCircleColor:(nullable UIColor *)color
                       canvasSize:(CGSize)canvasSize
                       circleSize:(CGSize)circleSize;
+ (BOOL)validateArgumentWithName:(NSString *)argumentName
                           value:(NSUInteger)value
                            isIn:(NSArray<NSNumber *> *)possibleValues
                           error:(NSError *_Nullable *)errorRef;
+ (BOOL)validateArray:(NSArray<id> *)array
             minCount:(NSUInteger)minCount
             maxCount:(NSUInteger)maxCount
                 name:(NSString *)name
                error:(NSError *_Nullable *)errorRef;
+ (BOOL)validateNetworkURL:(NSURL *)URL name:(NSString *)name error:(NSError *_Nullable *)errorRef;
+ (BOOL)validateRequiredValue:(id)value name:(NSString *)name error:(NSError *_Nullable *)errorRef;

@end

NS_ASSUME_NONNULL_END
