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

#import "FBSDKAEMAdvertiserRuleMatching.h"
#import "FBSDKAEMAdvertiserRuleOperator.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMAdvertiserSingleEntryRule)
@interface FBSDKAEMAdvertiserSingleEntryRule : NSObject<FBSDKAEMAdvertiserRuleMatching, NSCopying, NSSecureCoding>

@property (nonatomic, readonly, assign) FBSDKAEMAdvertiserRuleOperator operator;

@property (nonatomic, readonly) NSString *paramKey;

@property (nullable, nonatomic, readonly) NSString *linguisticCondition;

@property (nullable, nonatomic, readonly) NSNumber *numericalCondition;

@property (nullable, nonatomic, readonly) NSArray *arrayCondition;

- (instancetype)initWithOperator:(FBSDKAEMAdvertiserRuleOperator)op
                        paramKey:(NSString *)paramKey
             linguisticCondition:(nullable NSString *)linguisticCondition
              numericalCondition:(nullable NSNumber *)numericalCondition
                  arrayCondition:(nullable NSArray *)arrayCondition;

@end

NS_ASSUME_NONNULL_END

#endif
