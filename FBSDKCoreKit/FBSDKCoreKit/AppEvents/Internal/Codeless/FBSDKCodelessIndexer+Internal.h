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

// TODO: Can these all be forward decls?

#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKCodelessIndexer.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKEnableable.h"
#import "FBSDKGraphRequestConnectionFactoryProtocol.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKSwizzling.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCodelessIndexer (Internal) <FBSDKEnableable>

+ (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
             serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                   store:(id<FBSDKDataPersisting>)store
           graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                                swizzler:(Class<FBSDKSwizzling>)swizzler
                                settings:(id<FBSDKSettings>)settings
                    advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertisingIDProvider;

@end

NS_ASSUME_NONNULL_END

#endif
