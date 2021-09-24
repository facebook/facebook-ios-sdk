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

 #import "FBSDKAppLinkUtility.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKInfoDictionaryProviding;
@protocol FBSDKAppEventDropDetermining;
@protocol FBSDKAppEventParametersExtracting;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKSettings;
@protocol FBSDKAppEventsConfigurationProviding;
@protocol FBSDKAdvertiserIDProviding;

@interface FBSDKAppLinkUtility (Internal)

@property (class, nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (class, nullable, nonatomic) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (class, nullable, nonatomic) id<FBSDKAdvertiserIDProviding> advertiserIDProvider;
@property (class, nullable, nonatomic) id<FBSDKAppEventDropDetermining> appEventsDropDeterminer;
@property (class, nullable, nonatomic) id<FBSDKAppEventParametersExtracting> appEventParametersExtractor;

+ (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                  infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                settings:(id<FBSDKSettings>)settings
          appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                    advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
                 appEventsDropDeterminer:(id<FBSDKAppEventDropDetermining>)appEventsDropDeterminer
             appEventParametersExtractor:(id<FBSDKAppEventParametersExtracting>)appEventParametersExtractor
NS_SWIFT_NAME(configure(graphRequestFactory:infoDictionaryProvider:settings:appEventsConfigurationProvider:advertiserIDProvider:appEventsDropDeterminer:appEventParametersExtractor:));

@end

NS_ASSUME_NONNULL_END

#endif
