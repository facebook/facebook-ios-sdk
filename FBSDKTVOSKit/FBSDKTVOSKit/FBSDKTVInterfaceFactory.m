/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTVInterfaceFactory.h"

#import <TVMLKit/TVElementFactory.h>

#import "FBSDKDeviceLoginButton.h"
#import "FBSDKTVLoginButtonElement.h"
#import "FBSDKTVLoginViewControllerElement.h"

static NSString *const FBSDKLoginButtonTag = @"FBSDKLoginButton";
static NSString *const FBSDKLoginViewControllerTag = @"FBSDKLoginViewController";

@interface FBSDKTVInterfaceFactory ()
@property (nonatomic) id<TVInterfaceCreating> interfaceCreator;
@end

@implementation FBSDKTVInterfaceFactory

- (instancetype)initWithInterfaceCreator:(id<TVInterfaceCreating>)interfaceCreator
{
  if ((self = [super init])) {
    _interfaceCreator = interfaceCreator;
  }

  [TVElementFactory registerViewElementClass:FBSDKTVLoginButtonElement.class forElementName:FBSDKLoginButtonTag];
  [TVElementFactory registerViewElementClass:FBSDKTVLoginViewControllerElement.class forElementName:FBSDKLoginViewControllerTag];
  return self;
}

#pragma mark - TVInterfaceCreating

- (nullable UIView *)viewForElement:(TVViewElement *)element
                       existingView:(UIView *)existingView
{
  if ([element isKindOfClass:FBSDKTVLoginButtonElement.class]) {
    FBSDKDeviceLoginButton *button = [[FBSDKDeviceLoginButton alloc] initWithFrame:CGRectZero];
    button.delegate = (FBSDKTVLoginButtonElement *)element;
    button.permissions = [self permissionsFromElement:element];
    button.redirectURL = [NSURL URLWithString:element.attributes[@"redirectURL"]];
    return button;
  }
  if ([_interfaceCreator respondsToSelector:@selector(viewForElement:existingView:)]) {
    return [_interfaceCreator viewForElement:element existingView:existingView];
  }
  return nil;
}

- (nullable UIViewController *)viewControllerForElement:(TVViewElement *)element existingViewController:(UIViewController *)existingViewController
{
  if ([element isKindOfClass:FBSDKTVLoginViewControllerElement.class]) {
    FBSDKDeviceLoginViewController *vc = [FBSDKDeviceLoginViewController new];
    vc.delegate = (FBSDKTVLoginViewControllerElement *)element;
    vc.permissions = [self permissionsFromElement:element];
    vc.redirectURL = [NSURL URLWithString:element.attributes[@"redirectURL"]];
    return vc;
  }
  if ([_interfaceCreator respondsToSelector:@selector(viewControllerForElement:existingViewController:)]) {
    return [_interfaceCreator viewControllerForElement:element existingViewController:existingViewController];
  }
  return nil;
}

- (nullable NSURL *)URLForResource:(NSString *)resourceName
{
  if ([_interfaceCreator respondsToSelector:@selector(URLForResource:)]) {
    return [_interfaceCreator URLForResource:resourceName];
  }
  return nil;
}

- (NSArray<NSString *> *)permissionsFromElement:(TVViewElement *)element
{
  NSMutableArray<NSString *> *permissions = [NSMutableArray new];
  [permissions addObjectsFromArray:[element.attributes[@"permissions"] componentsSeparatedByString:@","]];
  [permissions addObjectsFromArray:[element.attributes[@"readPermissions"] componentsSeparatedByString:@","]];
  [permissions addObjectsFromArray:[element.attributes[@"publishPermissions"] componentsSeparatedByString:@","]];

  return permissions;
}

@end
