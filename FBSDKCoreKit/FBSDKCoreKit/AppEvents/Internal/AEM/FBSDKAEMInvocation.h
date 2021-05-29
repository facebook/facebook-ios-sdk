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

 #import <Foundation/Foundation.h>

 #import "FBSDKAEMConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMInvocation)
@interface FBSDKAEMInvocation : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly, copy) NSString *campaignID;

@property (nonatomic, readonly, copy) NSString *ACSToken;

@property (nullable, nonatomic, readonly, copy) NSString *ACSSharedSecret;

@property (nullable, nonatomic, readonly, copy) NSString *ACSConfigID;

@property (nullable, nonatomic, readonly, copy) NSString *businessID;

@property (nonatomic, readonly, copy) NSDate *timestamp;

@property (nonatomic, readonly, copy) NSString *configMode;

/** The unique identifier of the config, it's the same as config's validFrom */
@property (nonatomic, readonly, assign) NSInteger configID;

@property (nonatomic, readonly) NSMutableSet<NSString *> *recordedEvents;

@property (nonatomic, readonly) NSMutableDictionary<NSString *, NSMutableDictionary *> *recordedValues;

@property (nonatomic, readonly, assign) NSInteger conversionValue;

@property (nonatomic, readonly, assign) NSInteger priority;

@property (nullable, nonatomic, readonly) NSDate *conversionTimestamp;

@property (nonatomic, assign) BOOL isAggregated;

+ (nullable instancetype)invocationWithAppLinkData:(nullable NSDictionary<id, id> *)applinkData;

- (BOOL)attributeEvent:(NSString *)event
              currency:(nullable NSString *)currency
                 value:(nullable NSNumber *)value
            parameters:(nullable NSDictionary *)parameters
               configs:(nullable NSDictionary<NSString *, NSArray<FBSDKAEMConfiguration *> *> *)configs;

- (BOOL)updateConversionValueWithConfigs:(nullable NSDictionary<NSString *, NSArray<FBSDKAEMConfiguration *> *> *)configs;

- (BOOL)isOutOfWindowWithConfigs:(nullable NSDictionary<NSString *, NSArray<FBSDKAEMConfiguration *> *> *)configs;

- (nullable NSString *)getHMAC:(NSInteger)delay;

@end

NS_ASSUME_NONNULL_END

#endif
