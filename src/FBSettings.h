/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

/*
 * Constants defining logging behavior.  Use with <[FBSettings setLoggingBehavior]>.
 */

/*! Log requests from FBRequest* classes */
extern NSString *const FBLoggingBehaviorFBRequests;

/*! Log requests from FBURLConnection* classes */
extern NSString *const FBLoggingBehaviorFBURLConnections;

/*! Include access token in logging. */
extern NSString *const FBLoggingBehaviorAccessTokens;

/*! Log session state transitions. */
extern NSString *const FBLoggingBehaviorSessionStateTransitions;

/*! Log performance characteristics */
extern NSString *const FBLoggingBehaviorPerformanceCharacteristics;

/*! Log Insights interactions */
extern NSString *const FBLoggingBehaviorInsights;

/*! Log errors likely to be preventable by the developer. This is in the default set of enabled logging behaviors. */
extern NSString *const FBLoggingBehaviorDeveloperErrors;

@class FBGraphObject;

/*! 
 @typedef
 
 @abstract Block type used to get install data that is returned by server when publishInstall is called
 @discussion
 */
typedef void (^FBInstallResponseDataHandler)(FBGraphObject *response, NSError *error);

/*!
 @typedef
 
 @abstract A list of beta features that can be enabled for the SDK. Beta features are for evaluation only,
 and are therefore only enabled for DEBUG builds. Beta features should not be enabled
 in release builds.
 */
typedef enum : NSUInteger {
  FBBetaFeaturesNone                 = 0,
#if defined(DEBUG) || defined(FB_BUILD_ONLY)
  FBBetaFeaturesShareDialog          = 1 << 0,
  FBBetaFeaturesOpenGraphShareDialog = 1 << 1,
#endif
} FBBetaFeatures;

@interface FBSettings : NSObject

/*!
 @method
 
 @abstract Retrieve the current Facebook SDK logging behavior.
 
 */
+ (NSSet *)loggingBehavior;

/*!
 @method

 @abstract Set the current Facebook SDK logging behavior.  This should consist of strings defined as
 constants with FBLogBehavior*, and can be constructed with, e.g., [NSSet initWithObjects:].

 @param loggingBehavior A set of strings indicating what information should be logged.  If nil is provided, the logging
 behavior is reset to the default set of enabled behaviors.  Set in an empty set in order to disable all logging.
 */
+ (void)setLoggingBehavior:(NSSet *)loggingBehavior;

/*! @abstract Retreive the current auto publish behavior.  Defaults to YES. */
+ (BOOL)shouldAutoPublishInstall;

/*!
 @method

 @abstract Sets whether the SDK will automatically publish an install to Facebook during first FBSession init
 or on first network request to Facebook.

 @param autoPublishInstall      If YES, automatically publish the install; if NO, do not.
 */
+ (void)setShouldAutoPublishInstall:(BOOL)autoPublishInstall;

// For best results, call this function during app activation.
/*!
 @method

 @abstract Manually publish an attributed install to the facebook graph. Calling this method will implicitly 
 turn off auto-publish.  This method acquires the current attribution id from the facebook application, queries the
 graph API to determine if the application has install attribution enabled, publishes the id, and records 
 success to avoid reporting more than once.

 @param appID A specific appID to publish an install for.  If nil, uses [FBSession defaultAppID].
 */
+ (void)publishInstall:(NSString *)appID;

/*!
 @method

 @abstract Manually publish an attributed install to the Facebook graph, and return the server response back in
 the supplied handler.  Calling this method will implicitly turn off auto-publish.  This method acquires the 
 current attribution id from the facebook application, queries the graph API to determine if the application 
 has install attribution enabled, publishes the id, and records success to avoid reporting more than once.

 @param appID   A specific appID to publish an install for.  If nil, uses [FBSession defaultAppID].
 @param handler A block to call with the server's response.
 */
+ (void)publishInstall:(NSString *)appID
           withHandler:(FBInstallResponseDataHandler)handler;

/*!
 @method
 
 @abstract Retrieve the Client Token that has been set via [FBSettings setClientToken]
 */
+ (NSString *)clientToken;

/*!
 @method
 
 @abstract Sets the Client Token for the Facebook App.  This is needed for certain API calls when made anonymously,
 without a user-based Session. Calls to FBInsights logging events are examples of this, when there may 
 have been no user login established.
 
 @param clientToken  The Facebook App's "client token", which, for a given appid can be found in the Security 
 section of the Advanced tab of the Facebook App settings found at <https://developers.facebook.com/apps/[your-app-id]>
 
 */
+ (void)setClientToken:(NSString *)clientToken;

/*!
 @method
 
 @abstract Set the default Facebook Display Name to be used by the SDK. This should match
 the Display Name that has been set for the app with the corresponding Facebook App ID, in
 the Facebook App Dashboard
 
 @param displayName The default Facebook Display Name to be used by the SDK.
 */
+ (void)setDefaultDisplayName:(NSString *)displayName;

/*!
 @method
 
 @abstract Get the default Facebook Display Name used by the SDK. If not explicitly
 set, the default will be read from the application's plist.
 */
+ (NSString *)defaultDisplayName;

/*!
 @method
 
 @abstract Set the default Facebook App ID to use for sessions. The SDK allows the appID
 to be overridden per instance in certain cases (e.g. per instance of FBSession)
 
 @param appID The default Facebook App ID to be used by the SDK.
 */
+ (void)setDefaultAppID:(NSString*)appID;

/*!
 @method
 
 @abstract Get the default Facebook App ID used by the SDK. If not explicitly
 set, the default will be read from the application's plist. The SDK allows the appID
 to be overridden per instance in certain cases (e.g. per instance of FBSession)
 */
+ (NSString*)defaultAppID;
 
/*!
 @method
 
 @abstract Set the default url scheme suffix used by the SDK. The SDK allows the url
 scheme suffix to be overridden per instance in certain cases (e.g. per instance of FBSession)
 
 @param urlSchemeSuffix The default url scheme suffix to be used by the SDK.
 */
+ (void)setDefaultUrlSchemeSuffix:(NSString*)urlSchemeSuffix;

/*!
 @method
 
 @abstract Get the default url scheme suffix used for sessions.  If not
 explicitly set, the default will be read from the application's plist. The SDK allows the url
 scheme suffix to be overridden per instance in certain cases (e.g. per instance of FBSession)
 */
+ (NSString*)defaultUrlSchemeSuffix;

/*!
 @method
 
 @abstract Enables the specified beta features. Beta features are for evaluation only,
 and are therefore only enabled for debug builds. Beta features should not be enabled
 in release builds.
 
 @param betaFeatures The beta features to enable (expects a bitwise OR of FBBetaFeatures)
 */
+ (void)enableBetaFeatures:(NSUInteger)betaFeatures;

/*!
 @method
 
 @abstract Enables a beta feature. Beta features are for evaluation only,
 and are therefore only enabled for debug builds. Beta features should not be enabled
 in release builds.
 
 @param betaFeature The beta feature to enable.
 */
+ (void)enableBetaFeature:(FBBetaFeatures)betaFeature;

/*!
 @method
 
 @abstract Disables a beta feature.
 
 @param betaFeature The beta feature to disable.
 */
+ (void)disableBetaFeature:(FBBetaFeatures)betaFeature;

/*!
 @method

 @abstract Determines whether a beta feature is enabled or not.
 
 @param betaFeature The beta feature to check.
 
 @return YES if the beta feature is enabled, NO if not.
 */
+ (BOOL)isBetaFeatureEnabled:(FBBetaFeatures)betaFeature;

@end
