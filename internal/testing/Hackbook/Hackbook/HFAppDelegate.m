// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "HFAppDelegate.h"

@import FBSDKCoreKit;
@import FBSDKLoginKit;
@import FBSDKShareKit;

#import "AEM/AEMTestUtils.h"
#import "Console.h"
#import "MainViewController.h"
#import "NavigationController.h"
#import "Hackbook-Swift.h"

@implementation HFAppDelegate

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
  ConsoleLog(@"Incoming URL: %@", url);
  [AEMTestUtils setCampaignFromUrl:url];
  [AEMTestUtils setLoggingBehaviorsForNetworkRuquest];

  [[FBSDKApplicationDelegate sharedInstance] application:application
                                                 openURL:url
                                                 options:options];

  return YES;
}

// Deep linking using universal links
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *_Nullable))restorationHandler
{
  if (userActivity.activityType == NSUserActivityTypeBrowsingWeb) {
    NSURL *url = userActivity.webpageURL;
    ConsoleLog(@"Incoming URL: %@", url);
    [AEMTestUtils setCampaignFromUrl:url];
    [AEMTestUtils setLoggingBehaviorsForNetworkRuquest];
    [[FBSDKApplicationDelegate sharedInstance] application:application
                                      continueUserActivity:userActivity];
  }

  return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  ConsoleLog(@"application:didFinishLaunchingWithOptions: %@", launchOptions);
  [AEMTestUtils setLoggingBehaviorsForNetworkRuquest];
  [[FBSDKApplicationDelegate sharedInstance] application:application
                           didFinishLaunchingWithOptions:launchOptions];

  // Additional setup. Moved from the +initialize to be run after the SDK is initialized
  [FBSDKLoginButton class];
  [FBSDKProfilePictureView class];
  NSString *subdomain = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookDomainPart];
  if (subdomain && ![subdomain isEqualToString:@""]) {
    FBSDKSettings.sharedSettings.facebookDomainPart = subdomain;
  }
  NSString *graphAPIVersion = [[NSUserDefaults standardUserDefaults] objectForKey:GraphAPIVersion];
  if (GraphAPIVersion.length > 0) {
    FBSDKSettings.sharedSettings.graphAPIVersion = graphAPIVersion;
  }

  [self logE2ETestEnvironmentVariables];

  _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UINavigationController *nav = [[NavigationController alloc] initWithRootViewController:[[MainViewController alloc] init]];
  _window.rootViewController = nav;
  [_window makeKeyAndVisible];

  FBEndToEndOverlayView *overlay = [[FBEndToEndOverlayView alloc] initWithAppWindow:_window];
  [overlay setup];

  return YES;
}

- (void)logE2ETestEnvironmentVariables
{
  NSDictionary *environment = NSProcessInfo.processInfo.environment;
  NSString *isTesting = environment[@"IS_TESTING"];

  if (isTesting) {
    NSString *proxyHost = environment[@"LAB_PROXY_HOST"] ?: @"nil";
    NSString *proxyPort = environment[@"LAB_PROXY_PORT"] ?: @"nil";
    NSString *isUsingLabProxy = environment[@"LAB_PROXY"] ?: @"nil";
    NSString *sandboxDomain = environment[@"USER_DEFAULT_FBSandboxSubdomain"] ?: @"nil";
    NSString *userAgent = environment[@"JEST_CUSTOM_USER_AGENT"] ?: @"nil";

    NSDictionary *e2eInfo = @{
      @"Is E2E testing" : isTesting,
      @"Is using E2E lab proxy" : isUsingLabProxy,
      @"E2E Proxy Host" : proxyHost,
      @"E2E Proxy Port" : proxyPort,
      @"Sandbox Domain" : sandboxDomain,
      @"User Agent" : userAgent
    };
    [e2eInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      ConsoleLog(@"%@: %@", key, obj);
    }];
  }
}

@end
