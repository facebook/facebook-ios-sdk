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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FBSDKInternalUtilityProtocol.h"

NS_ASSUME_NONNULL_BEGIN

#define FBSDK_CANOPENURL_FACEBOOK @"fbauth2"
#define FBSDK_CANOPENURL_FBAPI @"fbapi"
#define FBSDK_CANOPENURL_MESSENGER @"fb-messenger-share-api"
#define FBSDK_CANOPENURL_MSQRD_PLAYER @"msqrdplayer"
#define FBSDK_CANOPENURL_SHARE_EXTENSION @"fbshareextension"

NS_SWIFT_NAME(InternalUtility)
@interface FBSDKInternalUtility : NSObject <FBSDKInternalUtility>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (class, nonnull, readonly) FBSDKInternalUtility *sharedUtility;

/**
 Returns bundle for returning localized strings

 We assume a convention of a bundle named FBSDKStrings.bundle, otherwise we
 return the main bundle.
 */
@property (nonatomic, strong, readonly) NSBundle *bundleForStrings;

/**
  Constructs an URL for the current app.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The app URL.
 */
- (NSURL *)appURLWithHost:(NSString *)host
                     path:(NSString *)path
          queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                    error:(NSError *__autoreleasing *)errorRef;

/**
  Parses an FB url's query params (and potentially fragment) into a dictionary.
 @param url The FB url.
 @return A dictionary with the key/value pairs.
 */
- (NSDictionary *)parametersFromFBURL:(NSURL *)url;

/**
  Constructs a Facebook URL.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
- (NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                path:(NSString *)path
                     queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                               error:(NSError *__autoreleasing *)errorRef;

/**
  Tests whether the supplied URL is a valid URL for opening in the browser.
 @param URL The URL to test.
 @return YES if the URL refers to an http or https resource, otherwise NO.
 */
- (BOOL)isBrowserURL:(NSURL *)URL;

/**
  Checks equality between 2 objects.

 Checks for pointer equality, nils, isEqual:.
 @param object The first object to compare.
 @param other The second object to compare.
 @return YES if the objects are equal, otherwise NO.
 */
- (BOOL)object:(id)object isEqualToObject:(id)other;

/**
  Extracts permissions from a response fetched from me/permissions
 @param responseObject the response
 @param grantedPermissions the set to add granted permissions to
 @param declinedPermissions the set to add declined permissions to.
 */
- (void)extractPermissionsFromResponse:(NSDictionary *)responseObject
                    grantedPermissions:(NSMutableSet *)grantedPermissions
                   declinedPermissions:(NSMutableSet *)declinedPermissions
                    expiredPermissions:(NSMutableSet *)expiredPermissions;

/**
  validates that the app ID is non-nil, throws an NSException if nil.
 */
- (void)validateAppID;

/**
 Validates that the client access token is non-nil, otherwise - throws an NSException otherwise.
 Returns the composed client access token.
 */
- (NSString *)validateRequiredClientAccessToken;

/**
  validates that the right URL schemes are registered, throws an NSException if not.
 */
- (void)validateURLSchemes;

/**
  Attempts to find the first UIViewController in the view's responder chain. Returns nil if not found.
 */
- (nullable UIViewController *)viewControllerForView:(UIView *)view;

/**
  returns true if the url scheme is registered in the CFBundleURLTypes
 */
- (BOOL)isRegisteredURLScheme:(NSString *)urlScheme;

/**
  returns currently displayed top view controller.
 */
- (nullable UIViewController *)topMostViewController;

/**
 returns the current key window
 */
- (nullable UIWindow *)findWindow;

#pragma mark - FB Apps Installed

@property (nonatomic, assign, readonly) BOOL isMessengerAppInstalled;
@property (nonatomic, assign, readonly) BOOL isMSQRDPlayerAppInstalled;

- (BOOL)isRegisteredCanOpenURLScheme:(NSString *)urlScheme;

@end

NS_ASSUME_NONNULL_END
