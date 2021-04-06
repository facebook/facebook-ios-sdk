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

NS_ASSUME_NONNULL_BEGIN

/*
 * Constants defining logging behavior.  Use with <[FBSDKSettings setLoggingBehavior]>.
 */

typedef NSString *const FBSDKLoggingBehavior NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(LoggingBehavior);

/** Include access token in logging. */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorAccessTokens;

/** Log performance characteristics */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorPerformanceCharacteristics;

/** Log FBSDKAppEvents interactions */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorAppEvents;

/** Log Informational occurrences */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorInformational;

/** Log cache errors. */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorCacheErrors;

/** Log errors from SDK UI controls */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorUIControlErrors;

/** Log debug warnings from API response, i.e. when friends fields requested, but user_friends permission isn't granted. */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorGraphAPIDebugWarning;

/** Log warnings from API response, i.e. when requested feature will be deprecated in next version of API.
 Info is the lowest level of severity, using it will result in logging all previously mentioned levels.
 */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorGraphAPIDebugInfo;

/** Log errors from SDK network requests */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorNetworkRequests;

/** Log errors likely to be preventable by the developer. This is in the default set of enabled logging behaviors. */
FOUNDATION_EXPORT FBSDKLoggingBehavior FBSDKLoggingBehaviorDeveloperErrors;

NS_ASSUME_NONNULL_END
