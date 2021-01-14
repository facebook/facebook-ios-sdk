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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKAppEventsConfigurationFixtures.h"
#import "FBSDKBridgeAPI+Testing.h"
#import "FBSDKCloseIcon.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKSKAdNetworkEvent.h"
#import "FBSDKSKAdNetworkRule.h"
#import "FBSDKServerConfigurationFixtures.h"
#import "FBSDKSessionProviding.h"
#import "FBSDKTestCase.h"
#import "FakeBundle.h"

NS_ASSUME_NONNULL_BEGIN

// Interfaces for Swift extensions on Objective-C Test classes
@interface FBSDKAppEventsUtilityTests : FBSDKTestCase
@end

// Categories needed to expose private methods to Swift
@interface FBSDKAppEventsConfigurationManager (Testing)

+ (void)_processResponse:(id)response error:(nullable NSError *)error;

@end

@interface FBSDKCloseIcon (Testing)

- (nullable UIImage *)imageWithSize:(CGSize)size
                       primaryColor:(UIColor *)primaryColor
                     secondaryColor:(UIColor *)secondaryColor
                              scale:(CGFloat)scale;

@end

NS_SWIFT_NAME(FBProfilePictureViewState)
@interface FBSDKProfilePictureViewState
@end

@interface FBSDKProfilePictureView (Testing)

- (void)_accessTokenDidChangeNotification:(NSNotification *)notification;
- (void)_profileDidChangeNotification:(NSNotification *)notification;
- (void)_updateImageWithProfile;
- (void)_updateImageWithAccessToken;
- (void)_updateImage;
- (void)_fetchAndSetImageWithURL:(NSURL *)imageURL state:(FBSDKProfilePictureViewState *)state;
- (nullable FBSDKProfilePictureViewState *)lastState;

@end

@interface FBSDKAccessToken (Testing)

+ (void)setCurrentAccessToken:(nullable FBSDKAccessToken *)token
          shouldDispatchNotif:(BOOL)shouldDispatchNotif;

@end

@interface FBSDKProfile (Testing)

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification;

@end

@interface FBSDKAuthenticationToken (Testing)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                             claims:(nullable FBSDKAuthenticationTokenClaims *)claims
                                jti:(NSString *)jti;

+ (void)setCurrentAuthenticationToken:(nullable FBSDKAuthenticationToken *)token
               shouldPostNotification:(BOOL)shouldPostNotification;

@end

NS_ASSUME_NONNULL_END
