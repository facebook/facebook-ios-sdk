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

// This deserves some explanation.
// Cocoapods - we define FBSDKCoreKit_Basics as a subspec so to import it we need to use
// the name of the module produced by the podspec which is FBSDKCoreKit. To be able
// to reference it as <FBSDKCoreKit_Basics> we need to publish a separate pod.
// Because of the way files in the subspec are made available to the pod, we do not need
// to use the bracket import syntax.
//
// BUCK - we define FBSDKCoreKit_Basics as a separate library so we must import it as
// <FBSDKCoreKit_Basics>
//
// Xcodeproj - we define FBSDKCoreKit_Basics as a distinct module with its own project
// so that we can import it as <FBSDKCoreKit_Basics>
//
// Swift Package Manager - basics is defined as a target and dependency of LegacyCoreKit
// so it can be imported with `@import FBSDKCoreKit_Basics` which allows us to reference
// public headers without bracket import syntax.

#if defined FBSDK_SWIFT_PACKAGE || defined FBSDKCOCOAPODS
 #import "FBSDKBase64.h"
 #import "FBSDKBasicUtility.h"
 #import "FBSDKCrashHandler.h"
 #import "FBSDKCrashHandler+CrashHandlerProtocol.h"
 #import "FBSDKCrashHandlerProtocol.h"
 #import "FBSDKCrashObserving.h"
 #import "FBSDKFileDataExtracting.h"
 #import "FBSDKFileManaging.h"
 #import "FBSDKInfoDictionaryProviding.h"
 #import "FBSDKJSONValue.h"
 #import "FBSDKLibAnalyzer.h"
 #import "FBSDKSafeCast.h"
 #import "FBSDKSessionProviding.h"
 #import "FBSDKTypeUtility.h"
 #import "FBSDKURLSession.h"
 #import "FBSDKURLSessionTask.h"
 #import "FBSDKUserDataStore.h"
 #import "NSBundle+InfoDictionaryProviding.h"
#else
 #import <FBSDKCoreKit_Basics/FBSDKBase64.h>
 #import <FBSDKCoreKit_Basics/FBSDKBasicUtility.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashHandler.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashHandler+CrashHandlerProtocol.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashHandlerProtocol.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashObserving.h>
 #import <FBSDKCoreKit_Basics/FBSDKFileDataExtracting.h>
 #import <FBSDKCoreKit_Basics/FBSDKFileManaging.h>
 #import <FBSDKCoreKit_Basics/FBSDKInfoDictionaryProviding.h>
 #import <FBSDKCoreKit_Basics/FBSDKJSONValue.h>
 #import <FBSDKCoreKit_Basics/FBSDKLibAnalyzer.h>
 #import <FBSDKCoreKit_Basics/FBSDKSafeCast.h>
 #import <FBSDKCoreKit_Basics/FBSDKSessionProviding.h>
 #import <FBSDKCoreKit_Basics/FBSDKTypeUtility.h>
 #import <FBSDKCoreKit_Basics/FBSDKURLSession.h>
 #import <FBSDKCoreKit_Basics/FBSDKURLSessionTask.h>
 #import <FBSDKCoreKit_Basics/FBSDKUserDataStore.h>
 #import <FBSDKCoreKit_Basics/NSBundle+InfoDictionaryProviding.h>
#endif
