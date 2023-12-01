// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "AppDelegate.h"

#import <objc/message.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

#import "AEMTestUtils.h"
// @lint-ignore CLANGTIDY
#import <FBSDKBetaKit/FBSDKBetaAppDelegate.h>

#import "CoffeeShop-Swift.h"
#import "ProductDetailViewController.h"
#import "SandboxViewController.h"

@import FBSDKCoreKit;

@implementation AppDelegate

static NSString *lytroDebugMessages;
static NSInteger const kStatusBarViewTag = 10098;

- (NSString *)modeString
{
#if defined(DEBUG)
  return @"Development (sandbox)";
#else
  return @"Production";
#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [[FBSDKApplicationDelegate sharedInstance] application:application
                           didFinishLaunchingWithOptions:launchOptions];
  // Override point for customization after application launch.
  NSSet<FBSDKLoggingBehavior> *behaviors =
  [NSSet setWithObjects:FBSDKLoggingBehaviorAppEvents, FBSDKLoggingBehaviorNetworkRequests, nil];
  FBSDKSettings.sharedSettings.loggingBehaviors = behaviors;
  FBSDKSettings.sharedSettings.advertiserTrackingEnabled = YES;
#ifdef BUCK
  FBSDKSettings.sharedSettings.userAgentSuffix = @"BUCK";
#endif

  _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[ProductsListTableViewController alloc] init]];
  _window.rootViewController = nav;
  [_window makeKeyAndVisible];

  // app developer should do this
#if !TARGET_OS_SIMULATOR
  [self registerForRemoteNotifications];
#endif

  [FBSDKSettings.sharedSettings setDataProcessingOptions:@[]];
  NSString *overrideSandbox = [[NSUserDefaults standardUserDefaults] stringForKey:kSandboxOverrideKey];
  if (overrideSandbox.length > 0) {
    [FBSDKSettings.sharedSettings setFacebookDomainPart:overrideSandbox];
    [self addRedStatusBarForDebuggingInSandbox];
  }

  [FBSDKAppLinkUtility fetchDeferredAppLink:^(NSURL *url, NSError *error) {
    if (error) {
      NSLog(@"Received error while fetching deferred app link %@", error);
    }
    if (url) {
      [[UIApplication sharedApplication] openURL:url];
    }
  }];

  // register KVO - only used for status bar change when in sandbox environment
  [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kSandboxOverrideKey options:NSKeyValueObservingOptionNew context:nil];

  [FBSDKBetaAppDelegate setup];

  return YES;
}

// register notification - should be done by app developer
- (void)registerForRemoteNotifications
{
  if (@available(iOS 10.0, *)) {
  #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError *_Nullable error) {
      if (!error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [[UIApplication sharedApplication] registerForRemoteNotifications];
        });
      }
    }];
  #endif
  } else {
    // Fallback on earlier versions
    // Code for old versions
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert
      | UIUserNotificationTypeBadge
      | UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  }
}

// register successfully - should be (partially) done by app developer
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  [FBSDKAppEvents.shared setPushNotificationsDeviceToken:deviceToken];
}

// register failed - should be done by app developer
- (void)                               application:(UIApplication *)application
  didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  NSLog(@"Failed to register: %@", error);
}

// notification received - should be done by app developer
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
  NSLog(@"notification options %@", userInfo);
  NSDictionary *aps = userInfo[@"aps"];
  if ([aps[@"content-available"] intValue] == 1) {
    NSLog(@"SILENT notification");
  } else {
    [self handleRemoteNotification:[UIApplication sharedApplication] userInfo:userInfo];
  }
  completionHandler(UIBackgroundFetchResultNoData);
}

- (void)handleRemoteNotification:(UIApplication *)application userInfo:(NSDictionary *)remoteNotif
{
  NSLog(@"handleRemoteNotification");
  NSLog(@"Handle Remote Notification Dictionary: %@", remoteNotif);
  // Handle Click of the Push Notification From Here
  // You can write a code to redirect user to specific screen of the app here
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  FBSDKURL *appLink = [FBSDKURL URLWithInboundURL:url sourceApplication:sourceApplication];
  if (appLink.isAutoAppLink) {
    [[[UIAlertView alloc] initWithTitle:@"Received Auto App link:"
                                message:[NSString stringWithFormat:@"product id: %@", appLink.appLinkData[@"product_id"]]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
  }
  return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                        openURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
}

+ (void)load
{
  Method original, swizzled;

  original = class_getClassMethod(objc_getClass("FBSDKLytroLogger"), @selector(printDebugMessage:));
  swizzled = class_getClassMethod([self class], @selector(printDebugMessage:));
  method_exchangeImplementations(original, swizzled);
}

+ (void)printDebugMessage:(NSString *)message
{
  printf("[Lytro Swizzled] %s\n", [message UTF8String]);

  lytroDebugMessages = [NSString stringWithFormat:@"%@\n%@", (lytroDebugMessages ? lytroDebugMessages : @""), message];
  UIApplication *application = [UIApplication sharedApplication];
  UIWindow *window = [application keyWindow];
  window.accessibilityValue = [lytroDebugMessages copy];
}

#pragma mark - Status Bar

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (object == [NSUserDefaults standardUserDefaults]) {
    if ([keyPath isEqualToString:kSandboxOverrideKey]) {
      if ([[change objectForKey:NSKeyValueChangeNewKey] stringValue].length > 0) {
        [self addRedStatusBarForDebuggingInSandbox];
      } else {
        [self removeRedStatusBarForDebuggingInSandbox];
      }
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)addRedStatusBarForDebuggingInSandbox
{
  UIView *statusBar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [[UIApplication sharedApplication] statusBarFrame].size.width, [[UIApplication sharedApplication] statusBarFrame].size.height)];
  statusBar.backgroundColor = [UIColor redColor];
  statusBar.tag = kStatusBarViewTag;
  [[UIApplication sharedApplication].keyWindow addSubview:statusBar];
}

- (void)removeRedStatusBarForDebuggingInSandbox
{
  NSArray *subViews = [self.window subviews];
  for (UIView *view in subViews) {
    if (view.tag == kStatusBarViewTag) {
      [view removeFromSuperview];
    }
  }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  if (@available(iOS 14, *)) {
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
      switch (status) {
        case ATTrackingManagerAuthorizationStatusAuthorized:
          NSLog(@"ATT Authorized");
          break;
        case ATTrackingManagerAuthorizationStatusDenied:
          NSLog(@"ATT Denied");
          break;
        case ATTrackingManagerAuthorizationStatusRestricted:
          NSLog(@"ATT Restricted");
          break;
        case ATTrackingManagerAuthorizationStatusNotDetermined:
          NSLog(@"ATT Not Determined");
          break;
      }
    }];
  }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Deep linking
// Open URI-scheme for iOS 9 and above
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *)options
{
  [AEMTestUtils setCampaignFromUrl:url];
  [[FBSDKApplicationDelegate sharedInstance] application:application
                                                 openURL:url
                                                 options:options];
  return YES;
}

// Deep linking using universal links
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *_Nullable))restorationHandler
{
  [[FBSDKApplicationDelegate sharedInstance] application:application
                                    continueUserActivity:userActivity];

  return YES;
}

@end
