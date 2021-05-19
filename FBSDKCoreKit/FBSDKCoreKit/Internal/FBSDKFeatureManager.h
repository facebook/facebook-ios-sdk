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

@protocol FBSDKGateKeeperManaging;

NS_ASSUME_NONNULL_BEGIN

/**
 FBSDKFeature enum
 Defines features in SDK

 Sample:
 FBSDKFeatureAppEvents = 0x00010000,
                            ^ ^ ^ ^
                            | | | |
                          kit | | |
                        feature | |
                      sub-feature |
                    sub-sub-feature
 1st byte: kit
 2nd byte: feature
 3rd byte: sub-feature
 4th byte: sub-sub-feature
 */
typedef NS_ENUM(NSUInteger, FBSDKFeature)
{
  FBSDKFeatureNone = 0x00000000,
  // Features in CoreKit
  /** Essential of CoreKit */
  FBSDKFeatureCore = 0x01000000,
  /** App Events */
  FBSDKFeatureAppEvents = 0x01010000,
  FBSDKFeatureCodelessEvents = 0x01010100,
  FBSDKFeatureRestrictiveDataFiltering = 0x01010200,
  FBSDKFeatureAAM = 0x01010300,
  FBSDKFeaturePrivacyProtection = 0x01010400,
  FBSDKFeatureSuggestedEvents = 0x01010401,
  FBSDKFeatureIntelligentIntegrity = 0x01010402,
  FBSDKFeatureModelRequest = 0x01010403,
  FBSDKFeatureEventDeactivation = 0x01010500,
  FBSDKFeatureSKAdNetwork = 0x01010600,
  FBSDKFeatureSKAdNetworkConversionValue = 0x01010601,
  FBSDKFeatureATELogging = 0x01010700,
  FBSDKFeatureAEM = 0x01010800,
  /** Instrument */
  FBSDKFeatureInstrument = 0x01020000,
  FBSDKFeatureCrashReport = 0x01020100,
  FBSDKFeatureCrashShield = 0x01020101,
  FBSDKFeatureErrorReport = 0x01020200,

  // Features in LoginKit
  /** Essential of LoginKit */
  FBSDKFeatureLogin = 0x02000000,

  // Features in ShareKit
  /** Essential of ShareKit */
  FBSDKFeatureShare = 0x03000000,

  // Features in GamingServicesKit
  /** Essential of GamingServicesKit */
  FBSDKFeatureGamingServices = 0x04000000,

} NS_SWIFT_NAME(SDKFeature);

typedef void (^FBSDKFeatureManagerBlock)(BOOL enabled);

NS_SWIFT_NAME(FeatureManager)
@interface FBSDKFeatureManager : NSObject

@property (class, nonatomic, strong, readonly) FBSDKFeatureManager *shared;

- (BOOL)isEnabled:(FBSDKFeature)feature;
- (void)checkFeature:(FBSDKFeature)feature
     completionBlock:(FBSDKFeatureManagerBlock)completionBlock;
- (void)disableFeature:(FBSDKFeature)feature;

@end

NS_ASSUME_NONNULL_END
