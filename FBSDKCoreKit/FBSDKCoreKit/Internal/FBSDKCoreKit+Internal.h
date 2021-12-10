/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#if defined BUCK

 #if !TARGET_OS_TV
  #import "FBSDKCodelessIndexer.h"
  #import "FBSDKMetadataIndexer.h"
  #import "FBSDKSKAdNetworkReporter.h"
  #import "FBSDKSuggestedEventsIndexer.h"
  #import "FBSDKViewHierarchy.h"
  #import "FBSDKViewHierarchyMacros.h"
  #import "FBSDKViewImpressionLogger.h"
 #else
  #import "FBSDKDeviceButton+Internal.h"
  #import "FBSDKDeviceViewControllerBase+Internal.h"
  #import "FBSDKModalFormPresentationController.h"
  #import "FBSDKSmartDeviceDialogView.h"
 #endif

 #import "FBSDKButton+Internal.h"
 #import "FBSDKDialogConfiguration.h"
 #import "FBSDKDynamicFrameworkLoader.h"
 #import "FBSDKErrorRecoveryAttempter.h"
 #import "FBSDKGateKeeperManager.h"
 #import "FBSDKGraphRequest+Internal.h"
 #import "FBSDKGraphRequestBody.h"
 #import "FBSDKGraphRequestConnection+Internal.h"
 #import "FBSDKGraphRequestFactoryProtocol.h"
 #import "FBSDKGraphRequestMetadata.h"
 #import "FBSDKGraphRequestPiggybackManager.h"
 #import "FBSDKImageDownloader.h"
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
 #import "FBSDKUnarchiverProvider.h"

#else

 #if !TARGET_OS_TV
  #import "../AppEvents/Internal/AAM/FBSDKMetadataIndexer.h"
  #import "../AppEvents/Internal/Codeless/FBSDKCodelessIndexer.h"
  #import "../AppEvents/Internal/SKAdNetwork/FBSDKSKAdNetworkReporter.h"
  #import "../AppEvents/Internal/ViewHierarchy/FBSDKViewHierarchy.h"
  #import "../AppEvents/Internal/ViewHierarchy/FBSDKViewHierarchyMacros.h"
  #import "FBSDKAuthenticationStatusUtility.h"
  #import "UI/FBSDKViewImpressionLogger.h"
 #else
  #import "Device/FBSDKDeviceButton+Internal.h"
  #import "Device/FBSDKDeviceViewControllerBase+Internal.h"
  #import "Device/FBSDKModalFormPresentationController.h"
  #import "Device/FBSDKSmartDeviceDialogView.h"
 #endif

 #import "../AppEvents/Internal/Integrity/FBSDKRestrictiveDataFilterManager.h"
 #import "ErrorRecovery/FBSDKErrorRecoveryAttempter.h"
 #import "FBSDKDynamicFrameworkLoader.h"
 #import "FBSDKImageDownloader.h"
 #import "FBSDKLogger+Logging.h"
 #import "FBSDKMath.h"
 #import "FBSDKProfile+Internal.h"
 #import "FBSDKProfilePictureView+Internal.h"
 #import "FBSDKSettings+Internal.h"
 #import "FBSDKSwizzler.h"
 #import "FBSDKUnarchiverProvider.h"
 #import "Network/FBSDKGraphRequest+Internal.h"
 #import "Network/FBSDKGraphRequestBody.h"
 #import "Network/FBSDKGraphRequestConnection+Internal.h"
 #import "Network/FBSDKGraphRequestMetadata.h"
 #import "Network/FBSDKGraphRequestPiggybackManager.h"
 #import "ServerConfiguration/FBSDKDialogConfiguration.h"
 #import "ServerConfiguration/FBSDKGateKeeperManager.h"
 #import "ServerConfiguration/FBSDKServerConfiguration.h"
 #import "ServerConfiguration/FBSDKServerConfiguration+Internal.h"
 #import "ServerConfiguration/FBSDKServerConfigurationManager.h"
 #import "ServerConfiguration/FBSDKServerConfigurationManager+Internal.h"
 #import "TokenCaching/FBSDKTokenCache.h"
 #import "UI/FBSDKButton+Internal.h"
 #import "UI/FBSDKLogo.h"

#endif
