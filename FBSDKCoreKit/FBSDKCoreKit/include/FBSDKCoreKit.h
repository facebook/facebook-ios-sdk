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

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKAccessToken+TokenStringProviding.h>
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
#import <FBSDKCoreKit/FBSDKAppURLSchemeProviding.h>
#import <FBSDKCoreKit/FBSDKApplicationDelegate.h>
#import <FBSDKCoreKit/FBSDKApplicationObserving.h>
#import <FBSDKCoreKit/FBSDKAuthenticationToken.h>
#import <FBSDKCoreKit/FBSDKAuthenticationToken+AuthenticationTokenProtocols.h>
#import <FBSDKCoreKit/FBSDKAuthenticationTokenClaims.h>
#import <FBSDKCoreKit/FBSDKAuthenticationTokenProtocols.h>
#import <FBSDKCoreKit/FBSDKButton.h>
#import <FBSDKCoreKit/FBSDKButtonImpressionTracking.h>
#import <FBSDKCoreKit/FBSDKConstants.h>
#import <FBSDKCoreKit/FBSDKCoreKitVersions.h>
#import <FBSDKCoreKit/FBSDKDeviceButton.h>
#import <FBSDKCoreKit/FBSDKDeviceDialogView.h>
#import <FBSDKCoreKit/FBSDKDeviceViewControllerBase.h>
#import <FBSDKCoreKit/FBSDKDynamicFrameworkLoaderProxy.h>
#import <FBSDKCoreKit/FBSDKDynamicSocialFrameworkLoader.h>
#import <FBSDKCoreKit/FBSDKError.h>
#import <FBSDKCoreKit/FBSDKFeatureChecking.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnection+GraphRequestConnecting.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnectionFactory.h>
#import <FBSDKCoreKit/FBSDKGraphRequestDataAttachment.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFactory.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFactoryProtocol.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFlags.h>
#import <FBSDKCoreKit/FBSDKGraphRequestProtocol.h>
#import <FBSDKCoreKit/FBSDKIcon.h>
#import <FBSDKCoreKit/FBSDKImpressionTrackingButton.h>
#import <FBSDKCoreKit/FBSDKInternalUtility.h>
#import <FBSDKCoreKit/FBSDKInternalUtility+AppAvailabilityChecker.h>
#import <FBSDKCoreKit/FBSDKInternalUtility+AppURLSchemeProviding.h>
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
#import <FBSDKCoreKit/FBSDKProductAvailability.h>
#import <FBSDKCoreKit/FBSDKProductCondition.h>
#import <FBSDKCoreKit/FBSDKRandom.h>
#import <FBSDKCoreKit/FBSDKServerConfigurationProvider.h>
#import <FBSDKCoreKit/FBSDKSettings.h>
#import <FBSDKCoreKit/FBSDKSettingsLogging.h>
#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>
#import <FBSDKCoreKit/FBSDKTokenStringProviding.h>
#import <FBSDKCoreKit/FBSDKTransformer.h>
#import <FBSDKCoreKit/FBSDKUserAgeRange.h>
#import <FBSDKCoreKit/FBSDKUtility.h>

#import <UIKit/UIKit.h>

#if !TARGET_OS_TV
 #import <FBSDKCoreKit/FBSDKAppLink.h>
 #import <FBSDKCoreKit/FBSDKAppLinkNavigation.h>
 #import <FBSDKCoreKit/FBSDKAppLinkResolver.h>
 #import <FBSDKCoreKit/FBSDKAppLinkResolverRequestBuilder.h>
 #import <FBSDKCoreKit/FBSDKAppLinkResolving.h>
 #import <FBSDKCoreKit/FBSDKAppLinkTarget.h>
 #import <FBSDKCoreKit/FBSDKAppLinkUtility.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPI.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPI+URLOpener.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIProtocol.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIRequest.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIRequestCreating.h>
 #import <FBSDKCoreKit/FBSDKBridgeAPIResponse.h>
 #import <FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.h>
 #import <FBSDKCoreKit/FBSDKInternalUtility+URLHosting.h>
 #import <FBSDKCoreKit/FBSDKInternalUtilityProtocol.h>
 #import <FBSDKCoreKit/FBSDKMeasurementEvent.h>
 #import <FBSDKCoreKit/FBSDKMutableCopying.h>
 #import <FBSDKCoreKit/FBSDKProfile.h>
 #import <FBSDKCoreKit/FBSDKProfile+ProfileProtocols.h>
 #import <FBSDKCoreKit/FBSDKProfilePictureView.h>
 #import <FBSDKCoreKit/FBSDKProfileProtocols.h>
 #import <FBSDKCoreKit/FBSDKShareDialogConfiguration.h>
 #import <FBSDKCoreKit/FBSDKURL.h>
 #import <FBSDKCoreKit/FBSDKURLHosting.h>
 #import <FBSDKCoreKit/FBSDKURLOpener.h>
 #import <FBSDKCoreKit/FBSDKURLOpening.h>
 #import <FBSDKCoreKit/FBSDKWebDialog.h>
 #import <FBSDKCoreKit/FBSDKWebDialogView.h>
 #import <FBSDKCoreKit/FBSDKWebViewAppLinkResolver.h>
 #import <FBSDKCoreKit/FBSDKWindowFinding.h>
#endif
