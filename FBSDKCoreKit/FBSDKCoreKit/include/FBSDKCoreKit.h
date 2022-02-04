/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKAccessTokenProtocols.h>
#import <FBSDKCoreKit/FBSDKAdvertisingTrackingStatus.h>
#import <FBSDKCoreKit/FBSDKAppAvailabilityChecker.h>
#import <FBSDKCoreKit/FBSDKAppEventName.h>
#import <FBSDKCoreKit/FBSDKAppEventParameterName.h>
#import <FBSDKCoreKit/FBSDKAppEventParameterProduct.h>
#import <FBSDKCoreKit/FBSDKAppEventParameterValue.h>
#import <FBSDKCoreKit/FBSDKAppEventUserDataType.h>
#import <FBSDKCoreKit/FBSDKAppEvents.h>
#import <FBSDKCoreKit/FBSDKAppEventsFlushBehavior.h>
#import <FBSDKCoreKit/FBSDKAppEventsNotificationName.h>
#import <FBSDKCoreKit/FBSDKAppURLSchemeProviding.h>
#import <FBSDKCoreKit/FBSDKApplicationDelegate.h>
#import <FBSDKCoreKit/FBSDKApplicationObserving.h>
#import <FBSDKCoreKit/FBSDKAuthenticationToken.h>
#import <FBSDKCoreKit/FBSDKAuthenticationTokenClaims.h>
#import <FBSDKCoreKit/FBSDKAuthenticationTokenProtocols.h>
#import <FBSDKCoreKit/FBSDKButton.h>
#import <FBSDKCoreKit/FBSDKButtonImpressionLogging.h>
#import <FBSDKCoreKit/FBSDKConstants.h>
#import <FBSDKCoreKit/FBSDKCoreKitVersions.h>
#import <FBSDKCoreKit/FBSDKDeviceButton.h>
#import <FBSDKCoreKit/FBSDKDeviceDialogView.h>
#import <FBSDKCoreKit/FBSDKDeviceViewControllerBase.h>
#import <FBSDKCoreKit/FBSDKDynamicFrameworkLoaderProxy.h>
#import <FBSDKCoreKit/FBSDKDynamicSocialFrameworkLoader.h>
#import <FBSDKCoreKit/FBSDKErrorCreating.h>
#import <FBSDKCoreKit/FBSDKErrorFactory.h>
#import <FBSDKCoreKit/FBSDKErrorRecoveryAttempting.h>
#import <FBSDKCoreKit/FBSDKFeatureChecking.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnectionDelegate.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnectionFactory.h>
#import <FBSDKCoreKit/FBSDKGraphRequestDataAttachment.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFactory.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFactoryProtocol.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFlags.h>
#import <FBSDKCoreKit/FBSDKGraphRequestProtocol.h>
#import <FBSDKCoreKit/FBSDKIcon.h>
#import <FBSDKCoreKit/FBSDKImpressionLoggingButton.h>
#import <FBSDKCoreKit/FBSDKInternalUtility.h>
#import <FBSDKCoreKit/FBSDKInternalUtilityProtocol.h>
#import <FBSDKCoreKit/FBSDKKeychainStore.h>
#import <FBSDKCoreKit/FBSDKKeychainStoreFactory.h>
#import <FBSDKCoreKit/FBSDKKeychainStoreProtocol.h>
#import <FBSDKCoreKit/FBSDKKeychainStoreProviding.h>
#import <FBSDKCoreKit/FBSDKLocation.h>
#import <FBSDKCoreKit/FBSDKLogger.h>
#import <FBSDKCoreKit/FBSDKLogging.h>
#import <FBSDKCoreKit/FBSDKLoggingBehavior.h>
#import <FBSDKCoreKit/FBSDKLoginTooltip.h>
#import <FBSDKCoreKit/FBSDKNetworkErrorChecker.h>
#import <FBSDKCoreKit/FBSDKNetworkErrorChecking.h>
#import <FBSDKCoreKit/FBSDKProductAvailability.h>
#import <FBSDKCoreKit/FBSDKProductCondition.h>
#import <FBSDKCoreKit/FBSDKRandom.h>
#import <FBSDKCoreKit/FBSDKServerConfigurationProvider.h>
#import <FBSDKCoreKit/FBSDKSettings.h>
#import <FBSDKCoreKit/FBSDKSettingsLogging.h>
#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>
#import <FBSDKCoreKit/FBSDKTokenStringProviding.h>
#import <FBSDKCoreKit/FBSDKTransformer.h>
#import <FBSDKCoreKit/FBSDKURLScheme.h>
#import <FBSDKCoreKit/FBSDKUserAgeRange.h>
#import <FBSDKCoreKit/FBSDKUtility.h>
#import <FBSDKCoreKit/__FBSDKLoggerCreating.h>

#import <UIKit/UIKit.h>

#if !TARGET_OS_TV
 #import <FBSDKCoreKit/FBSDKAppLink.h>
 #import <FBSDKCoreKit/FBSDKAppLinkNavigation.h>
 #import <FBSDKCoreKit/FBSDKAppLinkResolver.h>
 #import <FBSDKCoreKit/FBSDKAppLinkResolving.h>
 #import <FBSDKCoreKit/FBSDKAppLinkTarget.h>
 #import <FBSDKCoreKit/FBSDKAppLinkTargetProtocol.h>
 #import <FBSDKCoreKit/FBSDKAppLinkUtility.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPI.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIProtocol.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIRequest.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIRequestCreating.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIResponse.h>
 #import <FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.h>
 #import <FBSDKCoreKit/FBSDKInternalUtilityProtocol.h>
 #import <FBSDKCoreKit/FBSDKMeasurementEvent.h>
 #import <FBSDKCoreKit/FBSDKMutableCopying.h>
 #import <FBSDKCoreKit/FBSDKProfile.h>
 #import <FBSDKCoreKit/FBSDKProfilePictureView.h>
 #import <FBSDKCoreKit/FBSDKProfileProtocols.h>
 #import <FBSDKCoreKit/FBSDKShareDialogConfiguration.h>
 #import <FBSDKCoreKit/FBSDKURL.h>
 #import <FBSDKCoreKit/FBSDKURLHosting.h>
 #import <FBSDKCoreKit/FBSDKURLOpener.h>
 #import <FBSDKCoreKit/FBSDKURLOpening.h>
 #import <FBSDKCoreKit/FBSDKWebDialog.h>
 #import <FBSDKCoreKit/FBSDKWebDialogDelegate.h>
 #import <FBSDKCoreKit/FBSDKWebDialogView.h>
 #import <FBSDKCoreKit/FBSDKWebViewAppLinkResolver.h>
 #import <FBSDKCoreKit/_FBSDKWindowFinding.h>
#endif
