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

#if SWIFT_PACKAGE
 #import "FBSDKCoreKit.h"
#else
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#endif

#if defined FBSDKCOCOAPODS || defined BUCK

 #if !TARGET_OS_TV
  #import "FBSDKCodelessIndexer.h"
  #import "FBSDKMetadataIndexer.h"
  #import "FBSDKSKAdNetworkReporter.h"
  #import "FBSDKSuggestedEventsIndexer.h"
  #import "FBSDKUIUtility.h"
  #import "FBSDKViewHierarchy.h"
  #import "FBSDKViewHierarchyMacros.h"
  #import "FBSDKViewImpressionTracker.h"
 #else
  #import "FBSDKDeviceButton+Internal.h"
  #import "FBSDKDeviceDialogView.h"
  #import "FBSDKDeviceViewControllerBase+Internal.h"
  #import "FBSDKModalFormPresentationController.h"
  #import "FBSDKSmartDeviceDialogView.h"
 #endif

 #import "FBSDKButton+Subclass.h"
 #import "FBSDKDialogConfiguration.h"
 #import "FBSDKDynamicFrameworkLoader.h"
 #import "FBSDKError.h"
 #import "FBSDKErrorRecoveryAttempter.h"
 #import "FBSDKGateKeeperManager.h"
 #import "FBSDKGraphRequest+Internal.h"
 #import "FBSDKGraphRequestBody.h"
 #import "FBSDKGraphRequestConnection+Internal.h"
 #import "FBSDKGraphRequestConnectionFactory.h"
 #import "FBSDKGraphRequestConnectionProviding.h"
 #import "FBSDKGraphRequestFactory.h"
 #import "FBSDKGraphRequestMetadata.h"
 #import "FBSDKGraphRequestPiggybackManager.h"
 #import "FBSDKIcon.h"
 #import "FBSDKImageDownloader.h"
 #import "FBSDKInternalUtility.h"
 #import "FBSDKKeychainStore.h"
 #import "FBSDKLogger.h"
 #import "FBSDKLogger+Logging.h"
 #import "FBSDKLogging.h"
 #import "FBSDKLogo.h"
 #import "FBSDKMath.h"
 #import "FBSDKProfile+Internal.h"
 #import "FBSDKProfilePictureView+Internal.h"
 #import "FBSDKRestrictiveDataFilterManager.h"
 #import "FBSDKServerConfiguration.h"
 #import "FBSDKServerConfiguration+Internal.h"
 #import "FBSDKServerConfigurationManager.h"
 #import "FBSDKServerConfigurationManager+Internal.h"
 #import "FBSDKSettings+Internal.h"
 #import "FBSDKSwizzler.h"
 #import "FBSDKTokenCache.h"
 #import "FBSDKTokenStringProviding.h"
 #import "FBSDKUnarchiverProvider.h"

#else

 #if !TARGET_OS_TV
  #import "../AppEvents/Internal/AAM/FBSDKMetadataIndexer.h"
  #import "../AppEvents/Internal/Codeless/FBSDKCodelessIndexer.h"
  #import "../AppEvents/Internal/SKAdNetwork/FBSDKSKAdNetworkReporter.h"
  #import "../AppEvents/Internal/SuggestedEvents/FBSDKSuggestedEventsIndexer.h"
  #import "../AppEvents/Internal/ViewHierarchy/FBSDKViewHierarchy.h"
  #import "../AppEvents/Internal/ViewHierarchy/FBSDKViewHierarchyMacros.h"
  #import "FBSDKAuthenticationStatusUtility.h"
  #import "UI/FBSDKUIUtility.h"
  #import "UI/FBSDKViewImpressionTracker.h"
 #else
  #import "Device/FBSDKDeviceButton+Internal.h"
  #import "Device/FBSDKDeviceDialogView.h"
  #import "Device/FBSDKDeviceViewControllerBase+Internal.h"
  #import "Device/FBSDKModalFormPresentationController.h"
  #import "Device/FBSDKSmartDeviceDialogView.h"
 #endif

 #import "../AppEvents/Internal/Integrity/FBSDKRestrictiveDataFilterManager.h"
 #import "ErrorRecovery/FBSDKErrorRecoveryAttempter.h"
 #import "FBSDKDynamicFrameworkLoader.h"
 #import "FBSDKError.h"
 #import "FBSDKImageDownloader.h"
 #import "FBSDKInternalUtility.h"
 #import "FBSDKLogger.h"
 #import "FBSDKLogger+Logging.h"
 #import "FBSDKLogging.h"
 #import "FBSDKMath.h"
 #import "FBSDKProfile+Internal.h"
 #import "FBSDKProfilePictureView+Internal.h"
 #import "FBSDKSettings+Internal.h"
 #import "FBSDKSwizzler.h"
 #import "FBSDKTokenStringProviding.h"
 #import "FBSDKUnarchiverProvider.h"
 #import "Network/FBSDKGraphRequest+Internal.h"
 #import "Network/FBSDKGraphRequestBody.h"
 #import "Network/FBSDKGraphRequestConnection+Internal.h"
 #import "Network/FBSDKGraphRequestConnectionFactory.h"
 #import "Network/FBSDKGraphRequestConnectionProviding.h"
 #import "Network/FBSDKGraphRequestFactory.h"
 #import "Network/FBSDKGraphRequestMetadata.h"
 #import "Network/FBSDKGraphRequestPiggybackManager.h"
 #import "ServerConfiguration/FBSDKDialogConfiguration.h"
 #import "ServerConfiguration/FBSDKGateKeeperManager.h"
 #import "ServerConfiguration/FBSDKServerConfiguration.h"
 #import "ServerConfiguration/FBSDKServerConfiguration+Internal.h"
 #import "ServerConfiguration/FBSDKServerConfigurationManager.h"
 #import "ServerConfiguration/FBSDKServerConfigurationManager+Internal.h"
 #import "TokenCaching/FBSDKKeychainStore.h"
 #import "TokenCaching/FBSDKTokenCache.h"
 #import "UI/FBSDKButton+Subclass.h"
 #import "UI/FBSDKIcon.h"
 #import "UI/FBSDKLogo.h"

#endif
