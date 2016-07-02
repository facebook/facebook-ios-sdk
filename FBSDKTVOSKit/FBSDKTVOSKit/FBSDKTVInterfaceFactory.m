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

#import "FBSDKTVInterfaceFactory.h"

#import <FBSDKShareKit/FBSDKShareKit.h>

#import <TVMLKit/TVElementFactory.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKDeviceLoginButton.h"
#import "FBSDKTVLoginButtonElement.h"
#import "FBSDKTVLoginViewControllerElement.h"
#import "FBSDKTVShareButtonElement.h"

static NSString *const FBSDKLoginButtonTag = @"FBSDKLoginButton";
static NSString *const FBSDKShareButtonTag = @"FBSDKShareButton";
static NSString *const FBSDKLoginViewControllerTag = @"FBSDKLoginViewController";

static Class FBSDKDynamicallyLoadShareKitClassFromString(NSString *className)
{
  static NSMutableDictionary *classes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    classes = [NSMutableDictionary dictionary];
  });
  if (!classes[className]) {
    classes[className] = NSClassFromString(className);
  }
  Class clazz = classes[className];
  if (clazz == nil) {
    NSString *message = [NSString stringWithFormat:@"Unable to load class %1$@. Did you link FBSDKShareKit.framework or add [%1$@ class] in your application delegate?", className];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:message
                                 userInfo:nil];
  }
  return clazz;
}

@implementation FBSDKTVInterfaceFactory {
  id<TVInterfaceCreating> _interfaceCreator;
}

- (instancetype)init {
  return [self initWithInterfaceCreator:nil];
}

- (instancetype)initWithInterfaceCreator:(id<TVInterfaceCreating>)interfaceCreator
{
  if ((self = [super init])) {
    _interfaceCreator = interfaceCreator;
  }
  return self;
}

+ (void)initialize
{
  [TVElementFactory registerViewElementClass:[FBSDKTVLoginButtonElement class] forElementName:FBSDKLoginButtonTag];
  [TVElementFactory registerViewElementClass:[FBSDKTVLoginViewControllerElement class] forElementName:FBSDKLoginViewControllerTag];
  [TVElementFactory registerViewElementClass:[FBSDKTVShareButtonElement class] forElementName:FBSDKShareButtonTag];
}

#pragma mark - TVInterfaceCreating

- (UIView *)viewForElement:(TVViewElement *)element
              existingView:(UIView *)existingView
{
  if ([element isKindOfClass:[FBSDKTVLoginButtonElement class]]) {
    FBSDKDeviceLoginButton *button = [[FBSDKDeviceLoginButton alloc] initWithFrame:CGRectZero];
    button.delegate = (FBSDKTVLoginButtonElement *)element;
    button.publishPermissions = [element.attributes[@"publishPermissions"] componentsSeparatedByString:@","];
    button.readPermissions = [element.attributes[@"readPermissions"] componentsSeparatedByString:@","];
    button.redirectURL = [NSURL URLWithString:element.attributes[@"redirectURL"]];
    return button;
  } else if ([element isKindOfClass:[FBSDKTVShareButtonElement class]]) {
    FBSDKDeviceShareButton *button = [[FBSDKDynamicallyLoadShareKitClassFromString(@"FBSDKDeviceShareButton") alloc] initWithFrame:CGRectZero];
    id<FBSDKSharingContent> content = nil;
    if (element.attributes[@"href"]) {
      content = [[FBSDKDynamicallyLoadShareKitClassFromString(@"FBSDKShareLinkContent") alloc] init];
      content.contentURL = [NSURL URLWithString:element.attributes[@"href"]];

    } else {
      NSString *actionType = element.attributes[@"action_type"];
      NSURL *url = [NSURL URLWithString:element.attributes[@"object_url"]];
      NSString *key = element.attributes[@"key"];
      if (actionType.length > 0 && url && key.length > 0) {
        FBSDKShareOpenGraphAction *action = [FBSDKDynamicallyLoadShareKitClassFromString(@"FBSDKShareOpenGraphAction") actionWithType:actionType objectURL:url key:key];
        content = [[FBSDKDynamicallyLoadShareKitClassFromString(@"FBSDKShareOpenGraphContent") alloc] init];
        ((FBSDKShareOpenGraphContent *)content).action = action;
      }
    }

    if (content) {
      button.shareContent = content;
      return button;
    } else {
      NSString *message = [NSString stringWithFormat:@"Invalid parameters for %@ (%@)", element.elementIdentifier, element.elementName];
      @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:message
                                   userInfo:nil];
    }

  }
  if ([_interfaceCreator respondsToSelector:@selector(viewForElement:existingView:)]) {
    return [_interfaceCreator viewForElement:element existingView:existingView];
  }
  return nil;
}

- (UIViewController *)viewControllerForElement:(TVViewElement *)element existingViewController:(UIViewController *)existingViewController
{
  if ([element isKindOfClass:[FBSDKTVLoginViewControllerElement class]]) {
    FBSDKDeviceLoginViewController *vc = [[FBSDKDeviceLoginViewController alloc] init];
    vc.delegate = (FBSDKTVLoginViewControllerElement *)element;
    NSArray *publishPermissions = [element.attributes[@"publishPermissions"] componentsSeparatedByString:@","];
    vc.publishPermissions = publishPermissions;
    NSArray *readPermissions = [element.attributes[@"readPermissions"] componentsSeparatedByString:@","];
    vc.readPermissions = readPermissions;
    vc.redirectURL = [NSURL URLWithString:element.attributes[@"redirectURL"]];
    return vc;
  }
  if ([_interfaceCreator respondsToSelector:@selector(viewControllerForElement:existingViewController:)]) {
    return [_interfaceCreator viewControllerForElement:element existingViewController:existingViewController];
  }
  return nil;
}

- (NSURL *)URLForResource:(NSString *)resourceName
{
  if ([_interfaceCreator respondsToSelector:@selector(URLForResource:)]) {
    return [_interfaceCreator URLForResource:resourceName];
  }
  return nil;
}
@end
