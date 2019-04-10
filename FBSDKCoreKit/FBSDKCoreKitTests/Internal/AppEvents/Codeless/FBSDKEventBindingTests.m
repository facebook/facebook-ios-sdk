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

#import <XCTest/XCTest.h>

#import "FBSDKCodelessParameterComponent.h"
#import "FBSDKEventBinding.h"
#import "FBSDKEventBindingManager.h"
#import "FBSDKSampleEventBinding.h"

@interface FBSDKEventBindingTests : XCTestCase {
  UIWindow *window;
  FBSDKEventBindingManager *eventBindingManager;
  UIButton *btnBuy;
  UIButton *btnConfirm;
  UIStepper *stepper;
}

@end

@interface FBSDKEventBinding(Testing)

+ (NSString *)findParameterOfPath:(NSArray *)path
                         pathType:(NSString *)pathType
                       sourceView:(UIView *)sourceView;

@end

@implementation FBSDKEventBindingTests

- (void)setUp {
  [super setUp];

  if (@available(iOS 9.0, *)) {
    eventBindingManager = [[FBSDKEventBindingManager alloc]
                           initWithJSON:[FBSDKSampleEventBinding getSampleDictionary]];
    window = [[UIWindow alloc] init];
    UIViewController *vc = [[UIViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

    UITabBarController *tab = [[UITabBarController alloc] init];
    tab.viewControllers = @[nav];
    window.rootViewController = tab;

    UIStackView *firstStackView = [[UIStackView alloc] init];
    [vc.view addSubview:firstStackView];
    UIStackView *secondStackView = [[UIStackView alloc] init];
    [firstStackView addSubview:secondStackView];

    btnBuy = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBuy setTitle:@"Buy" forState:UIControlStateNormal];
    [firstStackView addSubview:btnBuy];

    UILabel *lblPrice = [[UILabel alloc] init];
    lblPrice.text = @"$2.0";
    [firstStackView addSubview:lblPrice];

    btnConfirm = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnConfirm setTitle:@"Confirm" forState:UIControlStateNormal];
    [firstStackView addSubview:btnConfirm];

    lblPrice = [[UILabel alloc] init];
    lblPrice.text = @"$3.0";
    [secondStackView addSubview:lblPrice];

    stepper = [[UIStepper alloc] init];
    [secondStackView addSubview:stepper];
  }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMatching {
  NSArray *bindings = [FBSDKEventBindingManager parseArray:[FBSDKSampleEventBinding getSampleDictionary][@"event_bindings"]];
  FBSDKEventBinding *binding = bindings[0];
  XCTAssertTrue([FBSDKEventBinding isViewMatchPath:stepper path:binding.path]);

  binding = bindings[1];
  FBSDKCodelessParameterComponent *component = binding.parameters[0];
  XCTAssertTrue([FBSDKEventBinding isViewMatchPath:btnBuy path:binding.path]);
  NSString *price = [FBSDKEventBinding findParameterOfPath:component.path  pathType:component.pathType sourceView:btnBuy];
  XCTAssertEqual(price, @"$2.0");

  binding = bindings[2];
  component = binding.parameters[0];
  XCTAssertTrue([FBSDKEventBinding isViewMatchPath:btnConfirm path:binding.path]);
  price = [FBSDKEventBinding findParameterOfPath:component.path pathType:component.pathType sourceView:btnConfirm];
  XCTAssertEqual(price, @"$3.0");
  component = binding.parameters[1];
  NSString *action = [FBSDKEventBinding findParameterOfPath:component.path pathType:component.pathType sourceView:btnConfirm];
  XCTAssertEqual(action, @"Confirm");

}

@end
