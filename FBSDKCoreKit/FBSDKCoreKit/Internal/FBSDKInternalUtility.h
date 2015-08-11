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

#define FBSDK_CANOPENURL_FACEBOOK @"fbauth2"
#define FBSDK_CANOPENURL_MESSENGER @"fb-messenger-api"

typedef NS_ENUM(int32_t, FBSDKUIKitVersion)
{
  FBSDKUIKitVersion_6_0 = 0x0944,
  FBSDKUIKitVersion_6_1 = 0x094C,
  FBSDKUIKitVersion_7_0 = 0x0B57,
  FBSDKUIKitVersion_7_1 = 0x0B77,
  FBSDKUIKitVersion_8_0 = 0x0CF6,
};

@interface FBSDKInternalUtility : NSObject

/*!
 @abstract Constructs the scheme for apps that come to the current app through the bridge.
 */
+ (NSString *)appURLScheme;

/*!
 @abstract Constructs an URL for the current app.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The app URL.
 */
+ (NSURL *)appURLWithHost:(NSString *)host
                     path:(NSString *)path
          queryParameters:(NSDictionary *)queryParameters
                    error:(NSError *__autoreleasing *)errorRef;

/*!
 @abstract Parses an FB url's query params (and potentially fragment) into a dictionary.
 @param url The FB url.
 @return A dictionary with the key/value pairs.
 */
+ (NSDictionary *)dictionaryFromFBURL:(NSURL *)url;

/*!
 @abstract Adds an object to an array if it is not nil.
 @param array The array to add the object to.
 @param object The object to add to the array.
 */
+ (void)array:(NSMutableArray *)array addObject:(id)object;

/*!
 @abstract Returns bundle for returning localized strings
 @discussion We assume a convention of a bundle named FBSDKStrings.bundle, otherwise we
  return the main bundle.
*/
+ (NSBundle *)bundleForStrings;

/*!
 @abstract Converts simple value types to the string equivelant for serializing to a request query or body.
 @param value The value to be converted.
 @return The value that may have been converted if able (otherwise the input param).
 */
+ (id)convertRequestValue:(id)value;

/*!
 @abstract Gets the milliseconds since the Unix Epoch.
 @discussion Changes in the system clock will affect this value.
 @return The number of milliseconds since the Unix Epoch.
 */
+ (unsigned long)currentTimeInMilliseconds;

/*!
 @abstract Sets an object for a key in a dictionary if it is not nil.
 @param dictionary The dictionary to set the value for.
 @param object The value to set after serializing to JSON.
 @param key The key to set the value for.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return NO if an error occurred while serializing the object, otherwise YES.
 */
+ (BOOL)dictionary:(NSMutableDictionary *)dictionary
setJSONStringForObject:(id)object
            forKey:(id<NSCopying>)key
             error:(NSError *__autoreleasing *)errorRef;

/*!
 @abstract Sets an object for a key in a dictionary if it is not nil.
 @param dictionary The dictionary to set the value for.
 @param object The value to set.
 @param key The key to set the value for.
 */
+ (void)dictionary:(NSMutableDictionary *)dictionary setObject:(id)object forKey:(id<NSCopying>)key;

/*!
 @abstract Constructs a Facebook URL.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
+ (NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                path:(NSString *)path
                     queryParameters:(NSDictionary *)queryParameters
                               error:(NSError *__autoreleasing *)errorRef;

/*!
 @abstract Constructs a Facebook URL.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param defaultVersion A version to add to the URL if none is found in the path.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
+ (NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                path:(NSString *)path
                     queryParameters:(NSDictionary *)queryParameters
                      defaultVersion:(NSString *)defaultVersion
                               error:(NSError *__autoreleasing *)errorRef;

/*!
 @abstract Tests whether the supplied URL is a valid URL for opening in the browser.
 @param URL The URL to test.
 @return YES if the URL refers to an http or https resource, otherwise NO.
 */
+ (BOOL)isBrowserURL:(NSURL *)URL;

/*!
 @abstract Tests whether the supplied bundle identifier references a Facebook app.
 @param bundleIdentifier The bundle identifier to test.
 @return YES if the bundle identifier refers to a Facebook app, otherwise NO.
 */
+ (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier;

/*!
 @abstract Tests whether the operating system is at least the specified version.
 @param version The version to test against.
 @return YES if the operating system is greater than or equal to the specified version, otherwise NO.
 */
+ (BOOL)isOSRunTimeVersionAtLeast:(NSOperatingSystemVersion)version;

/*!
 @abstract Tests whether the supplied bundle identifier references the Safari app.
 @param bundleIdentifier The bundle identifier to test.
 @return YES if the bundle identifier refers to the Safari app, otherwise NO.
 */
+ (BOOL)isSafariBundleIdentifier:(NSString *)bundleIdentifier;

/*!
 @abstract Tests whether the UIKit version that the current app was linked to is at least the specified version.
 @param version The version to test against.
 @return YES if the linked UIKit version is greater than or equal to the specified version, otherwise NO.
 */
+ (BOOL)isUIKitLinkTimeVersionAtLeast:(FBSDKUIKitVersion)version;

/*!
 @abstract Tests whether the UIKit version in the runtime is at least the specified version.
 @param version The version to test against.
 @return YES if the runtime UIKit version is greater than or equal to the specified version, otherwise NO.
 */
+ (BOOL)isUIKitRunTimeVersionAtLeast:(FBSDKUIKitVersion)version;

/*!
 @abstract Converts an object into a JSON string.
 @param object The object to convert to JSON.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @param invalidObjectHandler Handles objects that are invalid, returning a replacement value or nil to ignore.
 @return A JSON string or nil if the object cannot be converted to JSON.
 */
+ (NSString *)JSONStringForObject:(id)object
                            error:(NSError *__autoreleasing *)errorRef
             invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler;

/*!
 @abstract Checks equality between 2 objects.
 @discussion Checks for pointer equality, nils, isEqual:.
 @param object The first object to compare.
 @param other The second object to compare.
 @result YES if the objects are equal, otherwise NO.
 */
+ (BOOL)object:(id)object isEqualToObject:(id)other;

/*!
 @abstract Converts a JSON string into an object
 @param string The JSON string to convert.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return An NSDictionary, NSArray, NSString or NSNumber containing the object representation, or nil if the string
 cannot be converted.
 */
+ (id)objectForJSONString:(NSString *)string error:(NSError *__autoreleasing *)errorRef;

/*!
 @abstract Constructs a query string from a dictionary.
 @param dictionary The dictionary with key/value pairs for the query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @param invalidObjectHandler Handles objects that are invalid, returning a replacement value or nil to ignore.
 @result Query string representation of the parameters.
 */
+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionary
                                  error:(NSError *__autoreleasing *)errorRef
                   invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler;

/*!
 @abstract Tests whether the orientation should be manually adjusted for views outside of the root view controller.
 @discussion With the legacy layout the developer must worry about device orientation when working with views outside of
 the window's root view controller and apply the correct rotation transform and/or swap a view's width and height
 values.  If the application was linked with UIKit on iOS 7 or earlier or the application is running on iOS 7 or earlier
 then we need to use the legacy layout code.  Otherwise if the application was linked with UIKit on iOS 8 or later and
 the application is running on iOS 8 or later, UIKit handles all of the rotation complexity and the origin is always in
 the top-left and no rotation transform is necessary.
 @return YES if if the orientation must be manually adjusted, otherwise NO.
 */
+ (BOOL)shouldManuallyAdjustOrientation;

/*!
 @abstract Constructs an NSURL.
 @param scheme The scheme for the URL.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The URL.
 */
+ (NSURL *)URLWithScheme:(NSString *)scheme
                    host:(NSString *)host
                    path:(NSString *)path
         queryParameters:(NSDictionary *)queryParameters
                   error:(NSError *__autoreleasing *)errorRef;

/*!
 * @abstract Deletes all the cookies in the NSHTTPCookieStorage for Facebook web dialogs
 */
+ (void)deleteFacebookCookies;

/*!
 @abstract Extracts permissions from a response fetched from me/permissions
 @param responseObject the response
 @param grantedPermissions the set to add granted permissions to
 @param declinedPermissions the set to add decliend permissions to.
 */
+ (void)extractPermissionsFromResponse:(NSDictionary *)responseObject
                    grantedPermissions:(NSMutableSet *)grantedPermissions
                   declinedPermissions:(NSMutableSet *)declinedPermissions;

/*!
 @abstract Registers a transient object so that it will not be deallocated until unregistered
 @param object The transient object
 */
+ (void)registerTransientObject:(id)object;

/*!
 @abstract Unregisters a transient object that was previously registered with registerTransientObject:
 @param object The transient object
 */
+ (void)unregisterTransientObject:(id)object;

/*!
 @abstract validates that the app ID is non-nil, throws an NSException if nil.
 */
+ (void)validateAppID;

/*!
 @abstract validates that the right URL schemes are registered, throws an NSException if not.
 */
+ (void)validateURLSchemes;

/*!
 @abstract returns true if the url scheme is registered in the CFBundleURLTypes
 */
+ (BOOL)isRegisteredURLScheme:(NSString *)urlScheme;

#pragma mark - FB Apps Installed

+ (BOOL)isFacebookAppInstalled;
+ (BOOL)isMessengerAppInstalled;
+ (void)checkRegisteredCanOpenURLScheme:(NSString *)urlScheme;

#define FBSDKConditionalLog(condition, loggingBehavior, desc, ...) \
{ \
  if (!(condition)) { \
    NSString *msg = [NSString stringWithFormat:(desc), ##__VA_ARGS__]; \
    [FBSDKLogger singleShotLogEntry:loggingBehavior logEntry:msg]; \
  } \
}

#define FB_BASE_URL @"facebook.com"

@end
