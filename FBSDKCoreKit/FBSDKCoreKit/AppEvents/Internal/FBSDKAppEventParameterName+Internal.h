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

#import "FBSDKAppEventParameterName.h"

// MARK: - General

FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameImplicitlyLogged;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameInBackground;

// MARK: - Push Notifications

FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNamePushCampaign;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNamePushAction;

// MARK: - E-Commerce

FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameImplicitlyLoggedPurchase;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameInAppPurchaseType;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameProductTitle;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameTransactionID;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameTransactionDate;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameSubscriptionPeriod;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameIsStartTrial;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameHasFreeTrial;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameTrialPeriod;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameTrialPrice;

// MARK: - Time Spent

FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameSessionInterruptions;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameTimeBetweenSessions;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameSessionID;
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameLaunchSource;
