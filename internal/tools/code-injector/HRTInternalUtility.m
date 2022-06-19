// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "HRTInternalUtility.h"

#import <mach-o/dyld.h>
#import <sys/time.h>

typedef NS_ENUM(NSUInteger, HRTInternalUtilityVersionMask) {
  HRTInternalUtilityMajorVersionMask = 0xFFFF0000,
  // HRTInternalUtilityMinorVersionMask = 0x0000FF00, // unused
  // HRTInternalUtilityPatchVersionMask = 0x000000FF, // unused
};

typedef NS_ENUM(NSUInteger, HRTInternalUtilityVersionShift) {
  HRTInternalUtilityMajorVersionShift = 16,
  // HRTInternalUtilityMinorVersionShift = 8, // unused
  // HRTInternalUtilityPatchVersionShift = 0, // unused
};

@implementation HRTInternalUtility

#pragma mark - Class Methods
+ (uint64_t)currentTimeInMilliseconds
{
  struct timeval time;
  gettimeofday(&time, NULL);
  return ((uint64_t)time.tv_sec * 1000) + (time.tv_usec / 1000);
}

+ (void)extractPermissionsFromResponse:(NSDictionary *)responseObject
                    grantedPermissions:(NSMutableSet *)grantedPermissions
                   declinedPermissions:(NSMutableSet *)declinedPermissions
                    expiredPermissions:(NSMutableSet *)expiredPermissions
{
  NSArray *resultData = responseObject[@"data"];
  if (resultData.count > 0) {
    for (NSDictionary *permissionsDictionary in resultData) {
      NSString *permissionName = permissionsDictionary[@"permission"];
      NSString *status = permissionsDictionary[@"status"];

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

+ (BOOL)isBrowserURL:(NSURL *)URL
{
  NSString *scheme = URL.scheme.lowercaseString;
  return ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]);
}

+ (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier
{
  return ([bundleIdentifier hasPrefix:@"com.facebook."]
    || [bundleIdentifier hasPrefix:@".com.facebook."]);
}

+ (BOOL)isSafariBundleIdentifier:(NSString *)bundleIdentifier
{
  return ([bundleIdentifier isEqualToString:@"com.apple.mobilesafari"]
    || [bundleIdentifier isEqualToString:@"com.apple.SafariViewService"]);
}

+ (BOOL)isUIKitLinkTimeVersionAtLeast:(HRTUIKitVersion)version
{
  static int32_t linkTimeMajorVersion;
  static dispatch_once_t getVersionOnce;
  dispatch_once(&getVersionOnce, ^{
    int32_t linkTimeVersion = NSVersionOfLinkTimeLibrary("UIKit");
    linkTimeMajorVersion = [self getMajorVersionFromFullLibraryVersion:linkTimeVersion];
  });
  return (version <= linkTimeMajorVersion);
}

+ (BOOL)isUIKitRunTimeVersionAtLeast:(HRTUIKitVersion)version
{
  static int32_t runTimeMajorVersion;
  static dispatch_once_t getVersionOnce;
  dispatch_once(&getVersionOnce, ^{
    int32_t runTimeVersion = NSVersionOfRunTimeLibrary("UIKit");
    runTimeMajorVersion = [self getMajorVersionFromFullLibraryVersion:runTimeVersion];
  });
  return (version <= runTimeMajorVersion);
}

+ (int32_t)getMajorVersionFromFullLibraryVersion:(int32_t)version
{
  // Negative values returned by NSVersionOfRunTimeLibrary/NSVersionOfLinkTimeLibrary
  // are still valid version numbers, as long as it's not -1.
  // After bitshift by 16, the negatives become valid positive major version number.
  // We ran into this first time with iOS 12.
  if (version != -1) {
    return ((version & HRTInternalUtilityMajorVersionMask) >> HRTInternalUtilityMajorVersionShift);
  } else {
    return 0;
  }
}

+ (BOOL)object:(id)object isEqualToObject:(id)other;
{
  if (object == other) {
    return YES;
  }
  if (!object || !other) {
    return NO;
  }
  return [object isEqual:other];
}

+ (NSOperatingSystemVersion)operatingSystemVersion
{
  static NSOperatingSystemVersion operatingSystemVersion = {
    .majorVersion = 0,
    .minorVersion = 0,
    .patchVersion = 0,
  };
  static dispatch_once_t getVersionOnce;
  dispatch_once(&getVersionOnce, ^{
    if ([NSProcessInfo instancesRespondToSelector:@selector(operatingSystemVersion)]) {
      operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    } else {
      NSArray *components = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
      switch (components.count) {
        default:
        case 3:
          operatingSystemVersion.patchVersion = [components[2] integerValue];
        // fall through
        case 2:
          operatingSystemVersion.minorVersion = [components[1] integerValue];
        // fall through
        case 1:
          operatingSystemVersion.majorVersion = [components[0] integerValue];
          break;
        case 0:
          operatingSystemVersion.majorVersion = ([self isUIKitLinkTimeVersionAtLeast:HRTUIKitVersion_7_0] ? 7 : 6);
          break;
      }
    }
  });
  return operatingSystemVersion;
}

static NSMapTable *_transientObjects;

+ (void)registerTransientObject:(id)object
{
  NSAssert([NSThread isMainThread], @"Must be called from the main thread!");
  if (!_transientObjects) {
    _transientObjects = [[NSMapTable alloc] init];
  }
  NSUInteger count = ((NSNumber *)[_transientObjects objectForKey:object]).unsignedIntegerValue;
  [_transientObjects setObject:@(count + 1) forKey:object];
}

+ (UIViewController *)viewControllerForView:(UIView *)view
{
  if (![view isKindOfClass:[UIResponder class]]) {
    return nil;
  }

  UIResponder *responder = view.nextResponder;
  while (responder) {
    if ([responder isKindOfClass:[UIViewController class]]) {
      return (UIViewController *)responder;
    }
    responder = responder.nextResponder;
  }
  return nil;
}

#pragma mark - FB Apps Installed

+ (BOOL)isFacebookAppInstalled
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [HRTInternalUtility checkRegisteredCanOpenURLScheme:HRT_CANOPENURL_FACEBOOK];
  });
  return [self _canOpenURLScheme:HRT_CANOPENURL_FACEBOOK];
}

+ (BOOL)isMessengerAppInstalled
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [HRTInternalUtility checkRegisteredCanOpenURLScheme:HRT_CANOPENURL_MESSENGER];
  });
  return [self _canOpenURLScheme:HRT_CANOPENURL_MESSENGER];
}

+ (BOOL)isMSQRDPlayerAppInstalled
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [HRTInternalUtility checkRegisteredCanOpenURLScheme:HRT_CANOPENURL_MSQRD_PLAYER];
  });
  return [self _canOpenURLScheme:HRT_CANOPENURL_MSQRD_PLAYER];
}

#pragma mark - Helper Methods

+ (NSComparisonResult)_compareOperatingSystemVersion:(NSOperatingSystemVersion)version1
                                           toVersion:(NSOperatingSystemVersion)version2
{
  if (version1.majorVersion < version2.majorVersion) {
    return NSOrderedAscending;
  } else if (version1.majorVersion > version2.majorVersion) {
    return NSOrderedDescending;
  } else if (version1.minorVersion < version2.minorVersion) {
    return NSOrderedAscending;
  } else if (version1.minorVersion > version2.minorVersion) {
    return NSOrderedDescending;
  } else if (version1.patchVersion < version2.patchVersion) {
    return NSOrderedAscending;
  } else if (version1.patchVersion > version2.patchVersion) {
    return NSOrderedDescending;
  } else {
    return NSOrderedSame;
  }
}

+ (BOOL)_canOpenURLScheme:(NSString *)scheme
{
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = scheme;
  components.path = @"/";
  return [[UIApplication sharedApplication] canOpenURL:components.URL];
}

+ (UIWindow *)findWindow
{
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  if (window == nil || window.windowLevel != UIWindowLevelNormal) {
    for (window in [UIApplication sharedApplication].windows) {
      if (window.windowLevel == UIWindowLevelNormal) {
        break;
      }
    }
  }

  return window;
}

+ (UIViewController *)topMostViewController
{
  UIWindow *keyWindow = [self findWindow];
  // SDK expects a key window at this point, if it is not, make it one
  if (keyWindow != nil && !keyWindow.isKeyWindow) {
    [keyWindow makeKeyWindow];
  }

  UIViewController *topController = keyWindow.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }
  return topController;
}

+ (NSString *)hexadecimalStringFromData:(NSData *)data
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

+ (BOOL)isRegisteredURLScheme:(NSString *)urlScheme
{
  static dispatch_once_t fetchBundleOnce;
  static NSArray *urlTypes = nil;

  dispatch_once(&fetchBundleOnce, ^{
    urlTypes = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleURLTypes"];
  });
  for (NSDictionary *urlType in urlTypes) {
    NSArray *urlSchemes = [urlType valueForKey:@"CFBundleURLSchemes"];
    if ([urlSchemes containsObject:urlScheme]) {
      return YES;
    }
  }
  return NO;
}

@end
