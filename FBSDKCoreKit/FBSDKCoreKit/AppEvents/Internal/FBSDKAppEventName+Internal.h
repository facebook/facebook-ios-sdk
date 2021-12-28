/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventName.h"

// MARK: - Application Lifecycle

FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameInitializeSDK;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameBackgroundStatusAvailable;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameBackgroundStatusDenied;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameBackgroundStatusRestricted;

// MARK: - E-Commerce

FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameProductCatalogUpdate;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNamePurchaseFailed;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNamePurchaseRestored;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameSubscribeInitiatedCheckout;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameSubscribeFailed;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameSubscribeRestore;

// MARK: - Push Notifications

FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNamePushOpened;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNamePushTokenObtained;

// MARK: - Time Spent

FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameActivatedApp;
FOUNDATION_EXPORT FBSDKAppEventName const FBSDKAppEventNameDeactivatedApp;
