/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKInternalUtility+Internal.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <mach-o/dyld.h>
#import <sys/time.h>

#import "FBSDKSettings+Internal.h"

typedef NS_ENUM(NSUInteger, FBSDKInternalUtilityVersionMask) {
  FBSDKInternalUtilityMajorVersionMask = 0xFFFF0000,
  // FBSDKInternalUtilityMinorVersionMask = 0x0000FF00, // unused
  // FBSDKInternalUtilityPatchVersionMask = 0x000000FF, // unused
};

typedef NS_ENUM(NSUInteger, FBSDKInternalUtilityVersionShift) {
  FBSDKInternalUtilityMajorVersionShift = 16,
  // FBSDKInternalUtilityMinorVersionShift = 8, // unused
  // FBSDKInternalUtilityPatchVersionShift = 0, // unused
};

@interface FBSDKInternalUtility ()

@property (nullable, nonatomic) id<__FBSDKLoggerCreating> loggerFactory;
@property (nonatomic) BOOL isConfigured;
@property (nullable, nonatomic) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;

@end

@implementation FBSDKInternalUtility

// These are stored at the class level so that they can be reset in unit tests
static dispatch_once_t fetchApplicationQuerySchemesToken;
static dispatch_once_t checkIfFacebookAppInstalledToken;
static dispatch_once_t checkIfMessengerAppInstalledToken;
static dispatch_once_t checkRegisteredCanOpenUrlSchemesToken;
static dispatch_once_t checkOperatingSystemVersionToken;
static dispatch_once_t fetchUrlSchemesToken;

static BOOL ShouldOverrideHostWithGamingDomain(NSString *hostPrefix)
{
  return [FBSDKAuthenticationToken.currentAuthenticationToken respondsToSelector:@selector(graphDomain)]
  && [FBSDKAuthenticationToken.currentAuthenticationToken.graphDomain isEqualToString:@"gaming"]
  && ([hostPrefix isEqualToString:@"graph."] || [hostPrefix isEqualToString:@"graph-video."]);
}

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
static FBSDKInternalUtility *_shared;

+ (instancetype)sharedUtility
{
  @synchronized(self) {
    if (!_shared) {
      _shared = [self new];
    }
  }

  return _shared;
}

#pragma mark - Class Methods

- (void)configureWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                              loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory
                                   settings:(id<FBSDKSettings>)settings
                               errorFactory:(id<FBSDKErrorCreating>)errorFactory;
{
  self.infoDictionaryProvider = infoDictionaryProvider;
  self.loggerFactory = loggerFactory;
  self.settings = settings;
  self.errorFactory = errorFactory;
  self.isConfigured = YES;
}

- (NSString *)appURLScheme
{
  NSString *appID = (self.settings.appID ?: @"");
  NSString *suffix = (self.settings.appURLSchemeSuffix ?: @"");
  return [[NSString alloc] initWithFormat:@"fb%@%@", appID, suffix];
}

- (NSURL *)appURLWithHost:(NSString *)host
                     path:(NSString *)path
          queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                    error:(NSError *__autoreleasing *)errorRef
{
  return [self URLWithScheme:[self appURLScheme]
                        host:host
                        path:path
             queryParameters:queryParameters
                       error:errorRef];
}

- (NSDictionary<NSString *, id> *)parametersFromFBURL:(NSURL *)url
{
  // version 3.2.3 of the Facebook app encodes the parameters in the query but
  // version 3.3 and above encode the parameters in the fragment;
  // merge them together with fragment taking priority.
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
  [params addEntriesFromDictionary:[FBSDKBasicUtility dictionaryWithQueryString:url.query]];

  // Only get the params from the fragment if it has authorize as the host
  if ([url.host isEqualToString:@"authorize"]) {
    [params addEntriesFromDictionary:[FBSDKBasicUtility dictionaryWithQueryString:url.fragment]];
  }
  return params;
}

- (NSBundle *)bundleForStrings
{
  static NSBundle *bundle;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *stringsBundlePath = [[NSBundle bundleForClass:self.class]
                                   pathForResource:@"FacebookSDKStrings"
                                   ofType:@"bundle"];
    bundle = [NSBundle bundleWithPath:stringsBundlePath] ?: NSBundle.mainBundle;
  });
  return bundle;
}

- (uint64_t)currentTimeInMilliseconds
{
  struct timeval time;
  gettimeofday(&time, NULL);
  return ((uint64_t)time.tv_sec * 1000) + (time.tv_usec / 1000);
}

- (void)extractPermissionsFromResponse:(NSDictionary<NSString *, id> *)responseObject
                    grantedPermissions:(NSMutableSet<NSString *> *)grantedPermissions
                   declinedPermissions:(NSMutableSet<NSString *> *)declinedPermissions
                    expiredPermissions:(NSMutableSet<NSString *> *)expiredPermissions
{
  NSArray *resultData = [FBSDKTypeUtility dictionary:responseObject objectForKey:@"data" ofType:NSArray.class];
  if (resultData.count > 0) {
    for (NSDictionary<NSString *, id> *permissionsDictionary in resultData) {
      NSString *permissionName = [FBSDKTypeUtility dictionary:permissionsDictionary objectForKey:@"permission" ofType:NSString.class];
      NSString *status = [FBSDKTypeUtility dictionary:permissionsDictionary objectForKey:@"status" ofType:NSString.class];

      if (!permissionName || !status) {
        continue;
      }

      if ([status isEqualToString:@"granted"]) {
        [grantedPermissions addObject:permissionName];
      } else if ([status isEqualToString:@"declined"]) {
        [declinedPermissions addObject:permissionName];
      } else if ([status isEqualToString:@"expired"]) {
        [expiredPermissions addObject:permissionName];
      }
    }
  }
}

- (nullable NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                         path:(NSString *)path
                              queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                                        error:(NSError *__autoreleasing *)errorRef
{
  return [self facebookURLWithHostPrefix:hostPrefix
                                    path:path
                         queryParameters:queryParameters
                          defaultVersion:@""
                                   error:errorRef];
}

- (nullable NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                         path:(NSString *)path
                              queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                               defaultVersion:(NSString *)defaultVersion
                                        error:(NSError *__autoreleasing *)errorRef
{
  NSString *version = (defaultVersion.length > 0) ? defaultVersion : self.settings.graphAPIVersion;
  if (version.length) {
    version = [@"/" stringByAppendingString:version];
  }

  return [self _facebookURLWithHostPrefix:hostPrefix
                                     path:path
                          queryParameters:queryParameters
                           defaultVersion:version
                                    error:errorRef];
}

- (NSURL *)unversionedFacebookURLWithHostPrefix:(NSString *)hostPrefix
                                           path:(NSString *)path
                                queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                                          error:(NSError *__autoreleasing *)errorRef
{
  return [self _facebookURLWithHostPrefix:hostPrefix
                                     path:path
                          queryParameters:queryParameters
                           defaultVersion:@""
                                    error:errorRef];
}

- (NSURL *)_facebookURLWithHostPrefix:(NSString *)hostPrefix
                                 path:(NSString *)path
                      queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                       defaultVersion:(NSString *)version
                                error:(NSError *__autoreleasing *)errorRef
{
  if (hostPrefix.length && ![hostPrefix hasSuffix:@"."]) {
    hostPrefix = [hostPrefix stringByAppendingString:@"."];
  }

  NSString *host =
  ShouldOverrideHostWithGamingDomain(hostPrefix)
  ? @"fb.gg"
  : @"facebook.com";

  NSString *domainPart = self.settings.facebookDomainPart;
  if (domainPart.length) {
    host = [[NSString alloc] initWithFormat:@"%@.%@", domainPart, host];
  }
  host = [NSString stringWithFormat:@"%@%@", hostPrefix ?: @"", host ?: @""];

  if (path.length) {
    NSScanner *versionScanner = [[NSScanner alloc] initWithString:path];
    if ([versionScanner scanString:@"/v" intoString:NULL]
        && [versionScanner scanInteger:NULL]
        && [versionScanner scanString:@"." intoString:NULL]
        && [versionScanner scanInteger:NULL]) {
      id<FBSDKLogging> logger = [self.loggerFactory createLoggerWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
      [logger logEntry:[NSString stringWithFormat:@"Invalid Graph API version:%@, assuming %@ instead",
                        version,
                        self.settings.graphAPIVersion]];
      version = nil;
    }
    if (![path hasPrefix:@"/"]) {
      path = [@"/" stringByAppendingString:path];
    }
  }
  path = [[NSString alloc] initWithFormat:@"%@%@", version ?: @"", path ?: @""];

  return [self URLWithScheme:FBSDKURLSchemeHTTPS
                        host:host
                        path:path
             queryParameters:queryParameters
                       error:errorRef];
}

- (BOOL)isBrowserURL:(NSURL *)URL
{
  NSString *scheme = URL.scheme.lowercaseString;
  return ([scheme isEqualToString:FBSDKURLSchemeHTTP] || [scheme isEqualToString:FBSDKURLSchemeHTTPS]);
}

- (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier
{
  return ([bundleIdentifier hasPrefix:@"com.facebook."]
    || [bundleIdentifier hasPrefix:@".com.facebook."]);
}

- (BOOL)isSafariBundleIdentifier:(NSString *)bundleIdentifier
{
  return ([bundleIdentifier isEqualToString:@"com.apple.mobilesafari"]
    || [bundleIdentifier isEqualToString:@"com.apple.SafariViewService"]);
}

- (BOOL)object:(id)object isEqualToObject:(id)other
{
  if (object == other) {
    return YES;
  }
  if (!object || !other) {
    return NO;
  }
  return [object isEqual:other];
}

- (NSOperatingSystemVersion)operatingSystemVersion
{
  static NSOperatingSystemVersion operatingSystemVersion = {
    .majorVersion = 0,
    .minorVersion = 0,
    .patchVersion = 0,
  };
  dispatch_once(&checkOperatingSystemVersionToken, ^{
    operatingSystemVersion = NSProcessInfo.processInfo.operatingSystemVersion;
  });
  return operatingSystemVersion;
}

- (nullable NSURL *)URLWithScheme:(NSString *)scheme
                             host:(NSString *)host
                             path:(NSString *)path
                  queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                            error:(NSError *__autoreleasing *)errorRef
{
  if (![path hasPrefix:@"/"]) {
    path = [@"/" stringByAppendingString:path ?: @""];
  }

  NSString *queryString = nil;
  if (queryParameters.count) {
    NSError *queryStringError;
    NSString *queryStringFromParams = [FBSDKBasicUtility queryStringWithDictionary:queryParameters
                                                                             error:&queryStringError
                                                              invalidObjectHandler:NULL];
    if (queryStringFromParams) {
      queryString = [@"?" stringByAppendingString:queryStringFromParams];
    }
    if (!queryString) {
      if (errorRef != NULL) {
        *errorRef = [self.errorFactory invalidArgumentErrorWithName:@"queryParameters"
                                                              value:queryParameters
                                                            message:nil
                                                    underlyingError:queryStringError];
      }
      return nil;
    }
  }

  NSURL *const URL = [NSURL URLWithString:[NSString stringWithFormat:
                                           @"%@://%@%@%@",
                                           scheme ?: @"",
                                           host ?: @"",
                                           path ?: @"",
                                           queryString ?: @""]];
  if (errorRef != NULL) {
    if (URL) {
      *errorRef = nil;
    } else {
      *errorRef = [self.errorFactory unknownErrorWithMessage:@"Unknown error building URL."
                                                    userInfo:nil];
    }
  }
  return URL;
}

- (void)deleteFacebookCookies
{
  NSHTTPCookieStorage *cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage;
  NSArray<NSHTTPCookie *> *facebookCookies = [cookies cookiesForURL:[self facebookURLWithHostPrefix:@"m."
                                                                                               path:@"/dialog/"
                                                                                    queryParameters:@{}
                                                                                              error:NULL]];

  for (NSHTTPCookie *cookie in facebookCookies) {
    [cookies deleteCookie:cookie];
  }
}

static NSMapTable *_transientObjects;

- (void)registerTransientObject:(id)object
{
  NSAssert(NSThread.isMainThread, @"Must be called from the main thread!");
  if (!_transientObjects) {
    _transientObjects = [NSMapTable new];
  }
  NSUInteger count = ((NSNumber *)[_transientObjects objectForKey:object]).unsignedIntegerValue;
  [_transientObjects setObject:@(count + 1) forKey:object];
}

- (void)unregisterTransientObject:(__weak id)object
{
  if (!object) {
    return;
  }
  NSAssert(NSThread.isMainThread, @"Must be called from the main thread!");
  NSUInteger count = ((NSNumber *)[_transientObjects objectForKey:object]).unsignedIntegerValue;
  if (count == 1) {
    [_transientObjects removeObjectForKey:object];
  } else if (count != 0) {
    [_transientObjects setObject:@(count - 1) forKey:object];
  } else {
    NSString *msg = [NSString stringWithFormat:@"unregisterTransientObject:%@ count is 0. This may indicate a bug in the FBSDK. Please"
                     " file a report to developers.facebook.com/bugs if you encounter any problems. Thanks!", [object class]];
    id<FBSDKLogging> logger = [self.loggerFactory createLoggerWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
    [logger logEntry:msg];
  }
}

- (nullable UIViewController *)viewControllerForView:(UIView *)view
{
  UIResponder *responder = view.nextResponder;
  while (responder) {
    if ([responder isKindOfClass:UIViewController.class]) {
      return (UIViewController *)responder;
    }
    responder = responder.nextResponder;
  }
  return nil;
}

#pragma mark - FB Apps Installed

- (BOOL)isFacebookAppInstalled
{
  dispatch_once(&checkIfFacebookAppInstalledToken, ^{
    [self checkRegisteredCanOpenURLScheme:FBSDKURLSchemeFacebookAPI];
  });
  return [self _canOpenURLScheme:FBSDKURLSchemeFacebookAPI];
}

- (BOOL)isMessengerAppInstalled
{
  dispatch_once(&checkIfMessengerAppInstalledToken, ^{
    [self checkRegisteredCanOpenURLScheme:FBSDKURLSchemeMessengerApp];
  });
  return [self _canOpenURLScheme:FBSDKURLSchemeMessengerApp];
}

- (BOOL)_canOpenURLScheme:(NSString *)scheme
{
  scheme = [FBSDKTypeUtility coercedToStringValue:scheme];
  if (!scheme) {
    return NO;
  }

  NSURLComponents *components = [NSURLComponents new];
  @try {
    components.scheme = scheme;
  } @catch (NSException *exception) {
    NSString *msg = [NSString stringWithFormat:@"Invalid URL scheme provided: %@", scheme];
    id<FBSDKLogging> logger = [self.loggerFactory createLoggerWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
    [logger logEntry:msg];
    return NO;
  }

  components.path = @"/";
  return [UIApplication.sharedApplication canOpenURL:components.URL];
}

- (void)validateAppID
{
  [self validateConfiguration];
  if (!self.settings.appID) {
    NSString *reason = @"App ID not found. Add a string value with your app ID for the key "
    @"FacebookAppID to the Info.plist or call Settings.shared.appID.";
    @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
  }
}

- (NSString *)validateRequiredClientAccessToken
{
  [self validateConfiguration];
  if (!self.settings.clientToken) {
    NSString *reason = @"ClientToken is required to be set for this operation. "
    @"Set the FacebookClientToken in the Info.plist or set `Settings.shared.clientToken`. "
    @"You can find your client token in your App Settings -> Advanced.";
    @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
  }
  return [NSString stringWithFormat:@"%@|%@", self.settings.appID, self.settings.clientToken];
}

- (void)validateURLSchemes
{
  [self validateAppID];
  NSString *defaultUrlScheme = [NSString stringWithFormat:@"fb%@%@", self.settings.appID, self.settings.appURLSchemeSuffix ?: @""];
  if (![self isRegisteredURLScheme:defaultUrlScheme]) {
    NSString *reason = [NSString stringWithFormat:@"%@ is not registered as a URL scheme. Please add it in your Info.plist", defaultUrlScheme];
    @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
  }
}

- (void)validateFacebookReservedURLSchemes
{
  NSArray<FBSDKURLScheme> *schemes = @[
    FBSDKURLSchemeMessengerApp,
    FBSDKURLSchemeFacebookAPI
  ];

  for (FBSDKURLScheme scheme in schemes) {
    if ([self isRegisteredURLScheme:scheme]) {
      NSString *reason = [NSString stringWithFormat:@"%@ is registered as a URL scheme. Please move the entry from CFBundleURLSchemes in your Info.plist to LSApplicationQueriesSchemes. If you are trying to resolve \"canOpenURL: failed\" warnings, those only indicate that the Facebook app is not installed on your device or simulator and can be ignored.", scheme];
      @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
    }
  }
}

- (void)extendDictionaryWithDataProcessingOptions:(NSMutableDictionary<NSString *, id> *)parameters
{
  NSDictionary<NSString *, id> *dataProcessingOptions = self.settings.persistableDataProcessingOptions;
  if (dataProcessingOptions) {
    NSArray<NSString *> *options = (NSArray<NSString *> *)dataProcessingOptions[DATA_PROCESSING_OPTIONS];
    if (options && [options isKindOfClass:NSArray.class]) {
      NSString *optionsString = [FBSDKBasicUtility JSONStringForObject:options error:nil invalidObjectHandler:nil];
      [FBSDKTypeUtility dictionary:parameters
                         setObject:optionsString
                            forKey:DATA_PROCESSING_OPTIONS];
    }
    [FBSDKTypeUtility dictionary:parameters
                       setObject:dataProcessingOptions[DATA_PROCESSING_OPTIONS_COUNTRY]
                          forKey:DATA_PROCESSING_OPTIONS_COUNTRY];
    [FBSDKTypeUtility dictionary:parameters
                       setObject:dataProcessingOptions[DATA_PROCESSING_OPTIONS_STATE]
                          forKey:DATA_PROCESSING_OPTIONS_STATE];
  }
}

- (nullable UIWindow *)findWindow
{
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  UIWindow *topWindow = UIApplication.sharedApplication.keyWindow;
  #pragma clang diagnostic pop
  if (topWindow == nil || topWindow.windowLevel < UIWindowLevelNormal) {
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
      if (window.windowLevel >= topWindow.windowLevel && !window.isHidden) {
        topWindow = window;
      }
    }
  }

  if (topWindow != nil) {
    return topWindow;
  }

  // Find active key window from UIScene
  if (@available(iOS 13.0, tvOS 13, *)) {
    NSSet<UIScene *> *scenes = [UIApplication.sharedApplication valueForKey:@"connectedScenes"];
    for (UIScene *scene in scenes) {
      id activationState = [scene valueForKeyPath:@"activationState"];
      BOOL isActive = activationState != nil && [activationState integerValue] == 0;
      if (isActive) {
        Class WindowScene = NSClassFromString(@"UIWindowScene");
        if ([scene isKindOfClass:WindowScene]) {
          NSArray<UIWindow *> *windows = [scene valueForKeyPath:@"windows"];
          for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
              return window;
            } else if (window.windowLevel >= topWindow.windowLevel && !window.isHidden) {
              topWindow = window;
            }
          }
        }
      }
    }
  }

  if (topWindow == nil) {
    id<FBSDKLogging> logger = [self.loggerFactory createLoggerWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
    [logger logEntry:@"Unable to find a valid UIWindow"];
  }
  return topWindow;
}

- (nullable UIViewController *)topMostViewController
{
  UIWindow *keyWindow = [self findWindow];
  // SDK expects a key window at this point, if it is not, make it one
  if (keyWindow != nil && !keyWindow.isKeyWindow) {
    NSString *msg = [NSString stringWithFormat:@"Unable to obtain a key window, marking %@ as keyWindow", keyWindow.description];
    id<FBSDKLogging> logger = [self.loggerFactory createLoggerWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
    [logger logEntry:msg];
    [keyWindow makeKeyWindow];
  }

  UIViewController *topController = keyWindow.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }
  return topController;
}

#if !TARGET_OS_TV
- (UIInterfaceOrientation)statusBarOrientation
{
  if (@available(iOS 13.0, *)) {
    return [self findWindow].windowScene.interfaceOrientation;
  } else {
    return UIInterfaceOrientationUnknown;
  }
}

#endif

- (nullable NSString *)hexadecimalStringFromData:(NSData *)data
{
  NSUInteger dataLength = data.length;
  if (dataLength == 0) {
    return nil;
  }

  const unsigned char *dataBuffer = data.bytes;
  NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
  for (int i = 0; i < dataLength; ++i) {
    [hexString appendFormat:@"%02x", dataBuffer[i]];
  }
  return [hexString copy];
}

- (BOOL)isRegisteredURLScheme:(NSString *)urlScheme
{
  [self validateConfiguration];

  static NSArray *urlTypes = nil;
  dispatch_once(&fetchUrlSchemesToken, ^{
    urlTypes = [self.infoDictionaryProvider.infoDictionary valueForKey:@"CFBundleURLTypes"];
  });
  for (NSDictionary<NSString *, id> *urlType in urlTypes) {
    NSArray<NSString *> *urlSchemes = [urlType valueForKey:@"CFBundleURLSchemes"];
    if ([urlSchemes containsObject:urlScheme]) {
      return YES;
    }
  }
  return NO;
}

- (void)checkRegisteredCanOpenURLScheme:(NSString *)urlScheme
{
  static NSMutableSet<NSString *> *checkedSchemes = nil;
  dispatch_once(&checkRegisteredCanOpenUrlSchemesToken, ^{
    checkedSchemes = [NSMutableSet set];
  });

  @synchronized(self) {
    if ([checkedSchemes containsObject:urlScheme]) {
      return;
    } else {
      [checkedSchemes addObject:urlScheme];
    }
  }

  if (![self isRegisteredCanOpenURLScheme:urlScheme]) {
    NSString *reason = [NSString stringWithFormat:@"%@ is missing from your Info.plist under LSApplicationQueriesSchemes and is required.", urlScheme];
    id<FBSDKLogging> logger = [self.loggerFactory createLoggerWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
    [logger logEntry:reason];
  }
}

- (BOOL)isRegisteredCanOpenURLScheme:(NSString *)urlScheme
{
  static NSArray<NSString *> *schemes = nil;
  dispatch_once(&fetchApplicationQuerySchemesToken, ^{
    schemes = [self.infoDictionaryProvider.infoDictionary valueForKey:@"LSApplicationQueriesSchemes"];
  });

  return [schemes containsObject:urlScheme];
}

- (BOOL)isPublishPermission:(NSString *)permission
{
  return [permission hasPrefix:@"publish"]
  || [permission hasPrefix:@"manage"]
  || [permission isEqualToString:@"ads_management"]
  || [permission isEqualToString:@"create_event"]
  || [permission isEqualToString:@"rsvp_event"];
}

- (BOOL)isUnity
{
  NSString *userAgentSuffix = self.settings.userAgentSuffix;
  if (userAgentSuffix != nil && [userAgentSuffix rangeOfString:@"Unity"].location != NSNotFound) {
    return YES;
  }
  return NO;
}

- (void)validateConfiguration
{
#if DEBUG
  if (!self.isConfigured) {
    static NSString *const reason = @"As of v9.0, you must initialize the SDK prior to calling any methods or setting any properties. "
    "You can do this by calling `FBSDKApplicationDelegate`'s `application:didFinishLaunchingWithOptions:` method. "
    "Learn more: https://developers.facebook.com/docs/ios/getting-started"
    "If no `UIApplication` is available you can use `FBSDKApplicationDelegate`'s `initializeSDK` method.";
    @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
  }
#endif
}

#pragma mark - Testability

#if DEBUG && FBTEST

+ (void)reset
{
  if (fetchApplicationQuerySchemesToken) {
    fetchApplicationQuerySchemesToken = 0;
  }
  if (checkRegisteredCanOpenUrlSchemesToken) {
    checkRegisteredCanOpenUrlSchemesToken = 0;
  }
  if (checkIfFacebookAppInstalledToken) {
    checkIfFacebookAppInstalledToken = 0;
  }
  if (checkIfMessengerAppInstalledToken) {
    checkIfMessengerAppInstalledToken = 0;
  }
  if (checkOperatingSystemVersionToken) {
    checkOperatingSystemVersionToken = 0;
  }
  if (fetchUrlSchemesToken) {
    fetchUrlSchemesToken = 0;
  }

  self.sharedUtility.infoDictionaryProvider = nil;
  self.sharedUtility.loggerFactory = nil;
  self.sharedUtility.settings = nil;
  self.sharedUtility.errorFactory = nil;
  self.sharedUtility.isConfigured = NO;
}

#endif

@end
