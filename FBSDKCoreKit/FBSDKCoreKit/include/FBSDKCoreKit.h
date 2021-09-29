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

#import <UIKit/UIKit.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAccessToken+TokenStringProviding.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAdvertisingTrackingStatus.h"
#import "FBSDKAppAvailabilityChecker.h"
#import "FBSDKAppEventName.h"
#import "FBSDKAppEventParameterName.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsFlushBehavior.h"
#import "FBSDKAppURLSchemeProviding.h"
#import "FBSDKApplicationDelegate.h"
#import "FBSDKApplicationObserving.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKAuthenticationToken+AuthenticationTokenProtocols.h"
#import "FBSDKAuthenticationTokenClaims.h"
#import "FBSDKAuthenticationTokenProtocols.h"
#import "FBSDKButton.h"
#import "FBSDKButtonImpressionTracking.h"
#import "FBSDKConstants.h"
#import "FBSDKCoreKitVersions.h"
#import "FBSDKDeviceButton.h"
#import "FBSDKDeviceDialogView.h"
#import "FBSDKDeviceViewControllerBase.h"
#import "FBSDKDynamicFrameworkLoaderProxy.h"
#import "FBSDKDynamicSocialFrameworkLoader.h"
#import "FBSDKError.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKGraphRequestConnection+GraphRequestConnecting.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestFlags.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKIcon.h"
#import "FBSDKImpressionTrackingButton.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKInternalUtility+AppAvailabilityChecker.h"
#import "FBSDKInternalUtility+AppURLSchemeProviding.h"
#import "FBSDKInternalUtilityProtocol.h"
#import "FBSDKKeychainStore.h"
#import "FBSDKKeychainStoreFactory.h"
#import "FBSDKKeychainStoreProtocol.h"
#import "FBSDKKeychainStoreProviding.h"
#import "FBSDKLocation.h"
#import "FBSDKLogger.h"
#import "FBSDKLogging.h"
#import "FBSDKLoggingBehavior.h"
#import "FBSDKLoginTooltip.h"
#import "FBSDKProductAvailability.h"
#import "FBSDKProductCondition.h"
#import "FBSDKRandom.h"
#import "FBSDKServerConfigurationProvider.h"
#import "FBSDKSettings.h"
#import "FBSDKSettingsLogging.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKTokenStringProviding.h"
#import "FBSDKTransformer.h"
#import "FBSDKUserAgeRange.h"
#import "FBSDKUtility.h"

#if !TARGET_OS_TV
 #import "FBSDKAppLink.h"
 #import "FBSDKAppLinkNavigation.h"
 #import "FBSDKAppLinkResolver.h"
 #import "FBSDKAppLinkResolverRequestBuilder.h"
 #import "FBSDKAppLinkResolving.h"
 #import "FBSDKAppLinkTarget.h"
 #import "FBSDKAppLinkUtility.h"
 #import "FBSDKBridgeAPI.h"
 #import "FBSDKBridgeAPI+URLOpener.h"
 #import "FBSDKBridgeAPIProtocol.h"
 #import "FBSDKBridgeAPIProtocolType.h"
 #import "FBSDKBridgeAPIRequest.h"
 #import "FBSDKBridgeAPIRequestCreating.h"
 #import "FBSDKBridgeAPIResponse.h"
 #import "FBSDKGraphErrorRecoveryProcessor.h"
 #import "FBSDKInternalUtility+URLHosting.h"
 #import "FBSDKInternalUtilityProtocol.h"
 #import "FBSDKMeasurementEvent.h"
 #import "FBSDKMutableCopying.h"
 #import "FBSDKProfile.h"
 #import "FBSDKProfile+ProfileProtocols.h"
 #import "FBSDKProfilePictureView.h"
 #import "FBSDKProfileProtocols.h"
 #import "FBSDKShareDialogConfiguration.h"
 #import "FBSDKURL.h"
 #import "FBSDKURLHosting.h"
 #import "FBSDKURLOpener.h"
 #import "FBSDKURLOpening.h"
 #import "FBSDKWebDialog.h"
 #import "FBSDKWebDialogView.h"
 #import "FBSDKWebViewAppLinkResolver.h"
 #import "FBSDKWindowFinding.h"
#endif
