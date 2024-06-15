// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

@import AppTrackingTransparency;

#import "AppInLinkingTestViewController.h"

@import FBSDKCoreKit;

#import "Console.h"

#define TEST_PROFILE_LINK @"https://www.facebook.com/shawn.wiese.336"
#define TEST_PAGE_LINK @"https://www.facebook.com/hackbooktesting"
#define TEST_EVENT_LINK @"https://www.facebook.com/events/1433022110342108/"
#define TEST_FACEBOOK_LINK @"https://www.facebook.com/"
#define TEST_GROUP_LINK @"https://www.facebook.com/groups/359419590918598/"

@interface AppInLinkingTestViewController ()
@end

@implementation AppInLinkingTestViewController

#pragma mark - Actions
- (IBAction)InLinkToProfile:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_App_In_Linking_Facebook_Profile"];
  [self ResolveAndOpenUrl:TEST_PROFILE_LINK];
}

- (IBAction)InLinkToFacebookEvent:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_App_In_Linking_Facebook_Event"];
  [self ResolveAndOpenUrl:TEST_EVENT_LINK];
}

- (IBAction)InLinkToFacebookPage:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_App_In_Linking_Facebook_Page"];
  [self ResolveAndOpenUrl:TEST_PAGE_LINK];
}

- (IBAction)InLinkToDefaultFacebookDotCom:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_App_In_Linking_Facebook_Newsfeed"];
  [self ResolveAndOpenUrl:TEST_FACEBOOK_LINK];
}

- (IBAction)InLinkToFacebookGroup:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_App_In_Linking_Facebook_Group"];
  [self ResolveAndOpenUrl:TEST_GROUP_LINK];
}

// To use this, spin up a local server with some html you want.
// Replace the IP here with your computer's IP if you want to test
// using a device.
- (IBAction)resolveWebViewAppLink:(id)sender
{
  [self resolveAndOpenWebViewAppLinkUrl:@"http://0.0.0.0:8000"];
}

- (IBAction)FetchDeferredLink:(id)sender
{
  if (@available(iOS 14.0, *)) {
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
      if (status != ATTrackingManagerAuthorizationStatusAuthorized) {
        ConsoleLog(@"ATTrackingManager.AuthorizationStatus must be `authorized` for deferred deep linking to work. Read more at: https://developer.apple.com/documentation/apptrackingtransparency");
        return;
      } else {
        ConsoleLog(@"Fetching deferred app link");

        BOOL startingATEState = NO;
        BOOL isDomainHandlingDisabled = ![[FBSDKDomainHandler sharedInstance] isDomainHandlingEnabled];
        if (isDomainHandlingDisabled) {
          startingATEState = FBSDKSettings.sharedSettings.isAdvertiserTrackingEnabled;
          FBSDKSettings.sharedSettings.advertiserTrackingEnabled = YES;
        }

        [FBSDKAppLinkUtility fetchDeferredAppLink:^(NSURL *_Nullable url, NSError *_Nullable error) {
          if (url) {
            ConsoleSucceed(@"Successfully fetched deferred app link: %@", url.absoluteString);
          } else if (error) {
            ConsoleError(error, @"Fetching app link failed");
          } else {
            ConsoleLog(@"No url or error received");
          }

          if (isDomainHandlingDisabled) {
            // Reset ATE state
            FBSDKSettings.sharedSettings.advertiserTrackingEnabled = startingATEState;
          }
        }];
      }
    }];
  }
}

- (void)ResolveAndOpenUrl:(NSString *)urlString
{
  [FBSDKAppLinkNavigation setDefaultResolver:[FBSDKAppLinkResolver new]];

  [FBSDKAppLinkNavigation
   resolveAppLink:[NSURL URLWithString:urlString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     NSDictionary<NSString *, id> *referer_data = @{@"url" : @"hackbook-sample-app://",
                                                    @"app_name" : @"HackBook Internal for iOS"};
     FBSDKAppLinkNavigation *navigation = [FBSDKAppLinkNavigation navigationWithAppLink:link
                                                                                 extras:@{}
                                                                            appLinkData:@{@"referer_app_link" : referer_data}
                                                                               settings:FBSDKSettings.sharedSettings];
     [navigation navigate:nil];
   }];
}

- (void)resolveAndOpenWebViewAppLinkUrl:(NSString *)urlString
{
  [FBSDKAppLinkNavigation setDefaultResolver:FBSDKWebViewAppLinkResolver.sharedInstance];

  [FBSDKAppLinkNavigation
   resolveAppLink:[NSURL URLWithString:urlString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     NSDictionary<NSString *, id> *referer_data = @{@"url" : @"hackbook-sample-app://",
                                                    @"app_name" : @"HackBook Internal for iOS"};
     FBSDKAppLinkNavigation *navigation = [FBSDKAppLinkNavigation navigationWithAppLink:link
                                                                                 extras:@{}
                                                                            appLinkData:@{@"referer_app_link" : referer_data}
                                                                               settings:FBSDKSettings.sharedSettings];
     [navigation navigate:nil];
   }];
}

@end
