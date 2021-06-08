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

#ifdef BUCK

 #import <FBSDKCoreKit/FBSDKAccessToken.h>
 #import <FBSDKCoreKit/FBSDKAccessTokenProtocols.h>
 #import <FBSDKCoreKit/FBSDKAdvertisingTrackingStatus.h>
 #import <FBSDKCoreKit/FBSDKAppEventName.h>
 #import <FBSDKCoreKit/FBSDKAppEventParameterName.h>
 #import <FBSDKCoreKit/FBSDKAppEvents.h>
 #import <FBSDKCoreKit/FBSDKAppEventsFlushBehavior.h>
 #import <FBSDKCoreKit/FBSDKApplicationDelegate.h>
 #import <FBSDKCoreKit/FBSDKApplicationObserving.h>
 #import <FBSDKCoreKit/FBSDKAuthenticationToken.h>
 #import <FBSDKCoreKit/FBSDKAuthenticationTokenClaims.h>
 #import <FBSDKCoreKit/FBSDKButton.h>
 #import <FBSDKCoreKit/FBSDKButtonImpressionTracking.h>
 #import <FBSDKCoreKit/FBSDKConstants.h>
 #import <FBSDKCoreKit/FBSDKCopying.h>
 #import <FBSDKCoreKit/FBSDKCoreKitVersions.h>
 #import <FBSDKCoreKit/FBSDKDeviceButton.h>
 #import <FBSDKCoreKit/FBSDKDeviceViewControllerBase.h>
 #import <FBSDKCoreKit/FBSDKFeatureChecking.h>
 #import <FBSDKCoreKit/FBSDKGraphRequest.h>
 #import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>
 #import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>
 #import <FBSDKCoreKit/FBSDKGraphRequestConnection+GraphRequestConnecting.h>
 #import <FBSDKCoreKit/FBSDKGraphRequestDataAttachment.h>
 #import <FBSDKCoreKit/FBSDKGraphRequestFlags.h>
 #import <FBSDKCoreKit/FBSDKImpressionTrackingButton.h>
 #import <FBSDKCoreKit/FBSDKLocation.h>
 #import <FBSDKCoreKit/FBSDKLoggingBehavior.h>
 #import <FBSDKCoreKit/FBSDKSettings.h>
 #import <FBSDKCoreKit/FBSDKSettingsLogging.h>
 #import <FBSDKCoreKit/FBSDKSettingsProtocol.h>
 #import <FBSDKCoreKit/FBSDKUserAgeRange.h>
 #import <FBSDKCoreKit/FBSDKUtility.h>

 #if !TARGET_OS_TV
  #import <FBSDKCoreKit/FBSDKAppLink.h>
  #import <FBSDKCoreKit/FBSDKAppLinkNavigation.h>
  #import <FBSDKCoreKit/FBSDKAppLinkResolver.h>
  #import <FBSDKCoreKit/FBSDKAppLinkResolverRequestBuilder.h>
  #import <FBSDKCoreKit/FBSDKAppLinkResolving.h>
  #import <FBSDKCoreKit/FBSDKAppLinkTarget.h>
  #import <FBSDKCoreKit/FBSDKAppLinkUtility.h>
  #import <FBSDKCoreKit/FBSDKBridgeAPI.h>
  #import <FBSDKCoreKit/FBSDKBridgeAPIProtocol.h>
  #import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>
  #import <FBSDKCoreKit/FBSDKBridgeAPIRequest.h>
  #import <FBSDKCoreKit/FBSDKBridgeAPIResponse.h>
  #import <FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.h>
  #import <FBSDKCoreKit/FBSDKMeasurementEvent.h>
  #import <FBSDKCoreKit/FBSDKMutableCopying.h>
  #import <FBSDKCoreKit/FBSDKProfile.h>
  #import <FBSDKCoreKit/FBSDKProfilePictureView.h>
  #import <FBSDKCoreKit/FBSDKRandom.h>
  #import <FBSDKCoreKit/FBSDKURL.h>
  #import <FBSDKCoreKit/FBSDKURLOpening.h>
  #import <FBSDKCoreKit/FBSDKWebDialog.h>
  #import <FBSDKCoreKit/FBSDKWebViewAppLinkResolver.h>
 #endif

#else

 #import "FBSDKAccessToken.h"
 #import "FBSDKAccessTokenProtocols.h"
 #import "FBSDKAdvertisingTrackingStatus.h"
 #import "FBSDKAppEventName.h"
 #import "FBSDKAppEventParameterName.h"
 #import "FBSDKAppEvents.h"
 #import "FBSDKAppEventsFlushBehavior.h"
 #import "FBSDKApplicationDelegate.h"
 #import "FBSDKApplicationObserving.h"
 #import "FBSDKAuthenticationToken.h"
 #import "FBSDKAuthenticationTokenClaims.h"
 #import "FBSDKButton.h"
 #import "FBSDKButtonImpressionTracking.h"
 #import "FBSDKConstants.h"
 #import "FBSDKCopying.h"
 #import "FBSDKCoreKitVersions.h"
 #import "FBSDKDeviceButton.h"
 #import "FBSDKDeviceViewControllerBase.h"
 #import "FBSDKFeatureChecking.h"
 #import "FBSDKGraphRequest.h"
 #import "FBSDKGraphRequestConnecting.h"
 #import "FBSDKGraphRequestConnection.h"
 #import "FBSDKGraphRequestConnection+GraphRequestConnecting.h"
 #import "FBSDKGraphRequestDataAttachment.h"
 #import "FBSDKGraphRequestFlags.h"
 #import "FBSDKGraphRequestProtocol.h"
 #import "FBSDKImpressionTrackingButton.h"
 #import "FBSDKLocation.h"
 #import "FBSDKLoggingBehavior.h"
 #import "FBSDKRandom.h"
 #import "FBSDKSettings.h"
 #import "FBSDKSettingsLogging.h"
 #import "FBSDKSettingsProtocol.h"
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
  #import "FBSDKBridgeAPIProtocol.h"
  #import "FBSDKBridgeAPIProtocolType.h"
  #import "FBSDKBridgeAPIRequest.h"
  #import "FBSDKBridgeAPIResponse.h"
  #import "FBSDKGraphErrorRecoveryProcessor.h"
  #import "FBSDKMeasurementEvent.h"
  #import "FBSDKMutableCopying.h"
  #import "FBSDKProfile.h"
  #import "FBSDKProfilePictureView.h"
  #import "FBSDKURL.h"
  #import "FBSDKURLOpening.h"
  #import "FBSDKWebDialog.h"
  #import "FBSDKWebViewAppLinkResolver.h"
 #endif

#endif
