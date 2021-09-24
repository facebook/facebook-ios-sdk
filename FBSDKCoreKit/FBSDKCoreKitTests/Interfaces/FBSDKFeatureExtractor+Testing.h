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

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKFeatureExtracting.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKRulesFromKeyProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKFeatureExtractor (Testing)

+ (nullable id<FBSDKRulesFromKeyProvider>)keyProvider;

+ (void)configureWithRulesFromKeyProvider:(id<FBSDKRulesFromKeyProvider>)keyProvider;

+ (void)reset;

+ (nullable float *)getDenseFeatures:(NSDictionary<NSString *, id> *)viewHierarchy;

+ (BOOL)pruneTree:(NSMutableDictionary<NSString *, id> *)node
         siblings:(NSMutableArray *)siblings;

+ (float *)nonparseFeatures:(NSMutableDictionary<NSString *, id> *)node
                   siblings:(NSMutableArray *)siblings
                 screenname:(NSString *)screenname
             viewTreeString:(NSString *)viewTreeString;

+ (BOOL)isButton:(NSDictionary<NSString *, id> *)node;

+ (void)update:(NSDictionary<NSString *, id> *)node
          text:(NSMutableString *)buttonTextString
          hint:(NSMutableString *)buttonHintString;

+ (BOOL)foundIndicators:(NSArray *)indicators
               inValues:(NSArray *)values;

+ (float)regextMatch:(NSString *)pattern
                text:(NSString *)text;

+ (float *)parseFeatures:(NSMutableDictionary<NSString *, id> *)node;

@end

NS_ASSUME_NONNULL_END

#endif
