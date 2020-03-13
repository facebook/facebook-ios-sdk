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

#import <OCMock/OCMock.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKViewHierarchy.h"

@interface FBSDKViewHierarchyTests : XCTestCase {
  UIScrollView *scrollview;
  UILabel *label;
  UITextField *textField;
  UITextView *textView;
  UIButton *btn;
}
@end

@implementation FBSDKViewHierarchyTests

- (void)setUp
{
  scrollview = [[UIScrollView alloc] init];

  label = [[UILabel alloc] init];
  label.text = @"I am a label";
  [scrollview addSubview:label];

  textField = [[UITextField alloc] init];
  textField.text = @"I am a text field";
  textField.placeholder = @"text field placeholder";
  [scrollview addSubview:textField];

  textView = [[UITextView alloc] init];
  textView.text = @"I am a text view";
  [scrollview addSubview:textView];

  btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
  [btn setTitle:@"I am a button" forState:UIControlStateNormal];
  [scrollview addSubview:btn];
}

- (void)testRecursiveCaptureTree
{
  NSDictionary<NSString *, id> *tree = [FBSDKViewHierarchy recursiveCaptureTreeWithCurrentNode:scrollview
                                                                                    targetNode:nil
                                                                                 objAddressSet:nil
                                                                                          hash:NO];
  XCTAssertEqualObjects(tree[@"classname"], @"UIScrollView");
  XCTAssertEqual(((NSArray *)tree[@"childviews"]).count, 4);
  XCTAssertEqualObjects(tree[@"childviews"][0][@"classname"], @"UILabel");
  XCTAssertEqualObjects(tree[@"childviews"][1][@"classname"], @"UITextField");
  XCTAssertEqualObjects(tree[@"childviews"][2][@"classname"], @"UITextView");
  XCTAssertEqualObjects(tree[@"childviews"][3][@"classname"], @"UIButton");
}

- (void)testGetText
{
  XCTAssertEqualObjects([FBSDKViewHierarchy getText:label], @"I am a label");
  XCTAssertEqualObjects([FBSDKViewHierarchy getText:textField], @"I am a text field");
  XCTAssertEqualObjects([FBSDKViewHierarchy getText:textView], @"I am a text view");
  XCTAssertEqualObjects([FBSDKViewHierarchy getText:btn], @"I am a button");

  // test for no text
  XCTAssertEqualObjects([FBSDKViewHierarchy getText:scrollview], @"");
}

- (void)testGetHint
{
  XCTAssertEqualObjects([FBSDKViewHierarchy getHint:textField], @"text field placeholder");

  // test for getting hint for UITextField with inside labels ("text field placeholder" + " I am a label")
  [textField addSubview:label];
  XCTAssertEqualObjects([FBSDKViewHierarchy getHint:textField], @"text field placeholder I am a label");

  // test for no hint
  XCTAssertEqualObjects([FBSDKViewHierarchy getHint:label], @"");

  // test for getting hint for UINavigationController
  UINavigationController *NC = [[UINavigationController alloc] init];
  XCTAssertEqualObjects([FBSDKViewHierarchy getHint:NC], @"");
  UIViewController *VC = [[UIViewController alloc] init];
  [NC addChildViewController:VC];
  XCTAssertEqualObjects([FBSDKViewHierarchy getHint:NC], @"UIViewController");
}

@end
