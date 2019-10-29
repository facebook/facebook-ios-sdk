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

#import "FBSDKAppLink_Internal.h"

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKURL.h"

static Class autoAppLinkViewControllerClass;
static NSString *autoAppLinkIdentifier;
static NSString *autoAppLinkStoryBoard;
static FBSDKAutoAppLinkPresentationStyle autoAppLinkStyle;

NSString *const FBSDKAppLinkDataParameterName = @"al_applink_data";
NSString *const FBSDKAppLinkTargetKeyName = @"target_url";
NSString *const FBSDKAppLinkUserAgentKeyName = @"user_agent";
NSString *const FBSDKAppLinkExtrasKeyName = @"extras";
NSString *const FBSDKAppLinkRefererAppLink = @"referer_app_link";
NSString *const FBSDKAppLinkRefererAppName = @"app_name";
NSString *const FBSDKAppLinkRefererUrl = @"url";
NSString *const FBSDKAppLinkVersionKeyName = @"version";
NSString *const FBSDKAppLinkVersion = @"1.0";
NSString *const FBSDKAutoAppLinkEventName = @"fb_auto_applink";

@interface FBSDKAppLink () <FBSDKApplicationObserving>

@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, copy) NSArray<FBSDKAppLinkTarget *> *targets;
@property (nonatomic, strong) NSURL *webURL;

@property (nonatomic, assign, getter=isBackToReferrer) BOOL backToReferrer;

@end

@implementation FBSDKAppLink

+ (instancetype)appLinkWithSourceURL:(NSURL *)sourceURL
                             targets:(NSArray<FBSDKAppLinkTarget *> *)targets
                              webURL:(NSURL *)webURL
                    isBackToReferrer:(BOOL)isBackToReferrer {
    FBSDKAppLink *link = [[self alloc] initWithIsBackToReferrer:isBackToReferrer];
    link.sourceURL = sourceURL;
    link.targets = [targets copy];
    link.webURL = webURL;
    return link;
}

+ (instancetype)appLinkWithSourceURL:(NSURL *)sourceURL
                             targets:(NSArray<FBSDKAppLinkTarget *> *)targets
                              webURL:(NSURL *)webURL {
    return [self appLinkWithSourceURL:sourceURL
                              targets:targets
                               webURL:webURL
                     isBackToReferrer:NO];
}

- (FBSDKAppLink *)initWithIsBackToReferrer:(BOOL)backToReferrer {
    if ((self = [super init])) {
        _backToReferrer = backToReferrer;
    }
    return self;
}

#pragma mark - Auto App Link Methods

/**
 The Auto App Link is in Beta development and will be kept in Internal for now
*/
+ (FBSDKAppLink *)sharedInstance
{
  static FBSDKAppLink *_sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[self alloc] init];
  });
  return _sharedInstance;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  FBSDKURL *parsedUrl = [FBSDKURL URLWithURL:url];
  if (!parsedUrl.isAutoAppLink) {
    return NO;
  }
  UIViewController<FBSDKAutoAppLink> *vc = [FBSDKAppLink getAutoAppLinkViewController];
  if (vc) {
    [vc setAutoAppLinkData:parsedUrl.appLinkData];
    UIViewController *root = [FBSDKInternalUtility topMostViewController];
    UINavigationController *nv = root.navigationController;
    switch(autoAppLinkStyle) {
      case FBSDKAutoAppLinkPresentationStyleAuto:
        if (nv) {
          [nv pushViewController:vc animated:YES];
        } else {
          [root presentViewController:vc animated:YES completion:nil];
        }
        break;
      case FBSDKAutoAppLinkPresentationStylePresent:
        [root presentViewController:vc animated:YES completion:nil];
        break;
      case FBSDKAutoAppLinkPresentationStylePush:
        if (nv) {
          [nv pushViewController:vc animated:YES];
        } else {
          [root presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
        }
        break;
    }
  }
  [FBSDKAppEvents logInternalEvent:FBSDKAutoAppLinkEventName isImplicitlyLogged:YES];
  return YES;
}

+ (void)registerViewController:(Class)viewControllerClass
                         style:(FBSDKAutoAppLinkPresentationStyle)style
{
  autoAppLinkViewControllerClass = viewControllerClass;
  autoAppLinkStyle = style;
  [[FBSDKApplicationDelegate sharedInstance] addObserver:[FBSDKAppLink sharedInstance]];
}

+ (void)registerIdentifier:(NSString *)identifier
                storyBoard:(NSString *)storyBoard
                     style:(FBSDKAutoAppLinkPresentationStyle)style
{
  autoAppLinkIdentifier = identifier;
  autoAppLinkStoryBoard = storyBoard;
  autoAppLinkStyle = style;
  [[FBSDKApplicationDelegate sharedInstance] addObserver:[FBSDKAppLink sharedInstance]];
}

/**
 Instantiate Auto App Link viewcontroller with the registered information.
*/
+ (UIViewController<FBSDKAutoAppLink> *)getAutoAppLinkViewController
{
  if (autoAppLinkViewControllerClass) {
    if (![autoAppLinkViewControllerClass isSubclassOfClass:[UIViewController class]]) {
      return nil;
    }
    if (![autoAppLinkViewControllerClass conformsToProtocol:@protocol(FBSDKAutoAppLink)]) {
      return nil;
    }
    return [[autoAppLinkViewControllerClass alloc] init];
  } else if (autoAppLinkIdentifier && autoAppLinkStoryBoard) {
    @try {
      return [[UIStoryboard storyboardWithName:autoAppLinkStoryBoard
                                bundle:nil]
      instantiateViewControllerWithIdentifier:autoAppLinkIdentifier];
    } @catch (NSException *exception) { }
  }
  return nil;
}

@end
