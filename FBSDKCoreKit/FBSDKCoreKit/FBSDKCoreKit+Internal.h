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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#if !TARGET_OS_TV
#import "AppEvents/Internal/Codeless/FBSDKViewHierarchy.h"
#import "AppEvents/Internal/Codeless/FBSDKCodelessMacros.h"
#import "AppEvents/Internal/Codeless/FBSDKCodelessIndexer.h"
#import "Internal/Cryptography/FBSDKCrypto.h"
#import "Internal/FBSDKAudioResourceLoader.h"
#import "Internal/FBSDKContainerViewController.h"
#import "Internal/BridgeAPI/FBSDKBridgeAPI.h"
#import "Internal/FBSDKMonotonicTime.h"
#import "Internal/FBSDKSystemAccountStoreAdapter.h"
#import "Internal/FBSDKTriStateBOOL.h"
#import "Internal/UI/FBSDKCloseIcon.h"
#import "Internal/UI/FBSDKColor.h"
#import "Internal/UI/FBSDKMaleSilhouetteIcon.h"
#import "Internal/UI/FBSDKUIUtility.h"
#import "Internal/UI/FBSDKViewImpressionTracker.h"
#import "Internal/WebDialog/FBSDKWebDialog.h"
#else
#import "Internal/Device/FBSDKDeviceButton+Internal.h"
#import "Internal/Device/FBSDKDeviceDialogView.h"
#import "Internal/Device/FBSDKSmartDeviceDialogView.h"
#import "Internal/Device/FBSDKDeviceViewControllerBase+Internal.h"
#import "Internal/Device/FBSDKModalFormPresentationController.h"
#endif

#import "AppEvents/Internal/FBSDKAppEvents+Internal.h"
#import "AppEvents/Internal/FBSDKAppEventsState.h"
#import "AppEvents/Internal/FBSDKAppEventsStateManager.h"
#import "AppEvents/Internal/FBSDKAppEventsUtility.h"
#import "AppEvents/Internal/FBSDKTimeSpentData.h"
#import "Internal/Base64/FBSDKBase64.h"
#import "Internal/ErrorRecovery/FBSDKErrorRecoveryAttempter.h"
#import "Internal/FBSDKDynamicFrameworkLoader.h"
#import "Internal/FBSDKApplicationObserving.h"
#import "Internal/FBSDKApplicationDelegate+Internal.h"
#import "Internal/FBSDKDeviceRequestsHelper.h"
#import "Internal/FBSDKError.h"
#import "Internal/FBSDKImageDownloader.h"
#import "Internal/FBSDKInternalUtility.h"
#import "Internal/FBSDKLogger.h"
#import "Internal/FBSDKMath.h"
#import "Internal/FBSDKSettings+Internal.h"
#import "Internal/FBSDKSwizzler.h"
#import "Internal/FBSDKTypeUtility.h"
#import "Internal/Network/FBSDKGraphRequest+Internal.h"
#import "Internal/Network/FBSDKGraphRequestConnection+Internal.h"
#import "Internal/Network/FBSDKGraphRequestMetadata.h"
#import "Internal/ServerConfiguration/FBSDKDialogConfiguration.h"
#import "Internal/ServerConfiguration/FBSDKServerConfiguration+Internal.h"
#import "Internal/ServerConfiguration/FBSDKServerConfiguration.h"
#import "Internal/ServerConfiguration/FBSDKServerConfigurationManager+Internal.h"
#import "Internal/ServerConfiguration/FBSDKServerConfigurationManager.h"
#import "Internal/TokenCaching/FBSDKAccessTokenCache.h"
#import "Internal/TokenCaching/FBSDKAccessTokenCaching.h"
#import "Internal/TokenCaching/FBSDKKeychainStore.h"
#import "Internal/TokenCaching/FBSDKKeychainStoreViaBundleID.h"
#import "Internal/UI/FBSDKButton+Subclass.h"
#import "Internal/UI/FBSDKIcon.h"
#import "Internal/UI/FBSDKLogo.h"
