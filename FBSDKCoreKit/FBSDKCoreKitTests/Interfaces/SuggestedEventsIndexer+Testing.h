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

#import "FBSDKSuggestedEventsIndexer.h"

@protocol FBSDKGraphRequestProviding;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKFeatureExtracting;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSuggestedEventsIndexer (Testing)

@property (nonatomic, readonly) id<FBSDKGraphRequestProviding> requestProvider;
@property (nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) Class<FBSDKFeatureExtracting> featureExtractor;
@property (nullable, nonatomic, weak) id<FBSDKEventProcessing> eventProcessor;
@property (nonatomic, readonly) NSSet<NSString *> *optInEvents;
@property (nonatomic, readonly) NSSet<NSString *> *unconfirmedEvents;

+ (void)reset;

- (instancetype)initWithGraphRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
                 serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                    swizzler:(Class<FBSDKSwizzling>)swizzler
                                    settings:(id<FBSDKSettings>)settings
                                 eventLogger:(id<FBSDKEventLogging>)eventLogger
                            featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                              eventProcessor:(id<FBSDKEventProcessing>)eventProcessor
NS_SWIFT_NAME(init(requestProvider:serverConfigurationProvider:swizzler:settings:eventLogger:featureExtractor:eventProcessor:));

- (void)logSuggestedEvent:(NSString *)event
                     text:(NSString *)text
             denseFeature:(nullable NSString *)denseFeature;
- (void)predictEventWithUIResponder:(UIResponder *)uiResponder
                               text:(NSString *)text;
- (void)handleView:(UIView *)view
      withDelegate:(nullable id)delegate;
- (void)matchSubviewsIn:(nullable UIView *)view;

@end

NS_ASSUME_NONNULL_END
