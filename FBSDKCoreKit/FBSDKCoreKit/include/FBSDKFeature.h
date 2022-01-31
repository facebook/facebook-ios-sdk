/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

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

 @warning INTERNAL - DO NOT USE
 */
typedef NS_ENUM(NSUInteger, FBSDKFeature) {
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
  FBSDKFeatureAEMConversionFiltering = 0x01010801,
  FBSDKFeatureAEMCatalogMatching = 0x01010802,
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

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef void (^FBSDKFeatureManagerBlock)(BOOL enabled);

NS_ASSUME_NONNULL_END
