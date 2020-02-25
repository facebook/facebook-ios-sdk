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
}
@end

@implementation FBSDKViewHierarchyTests

- (void)setUp
{
  scrollview = [[UIScrollView alloc] init];

  UILabel *label = [[UILabel alloc] init];
  label.text = @"I am a label";
  [scrollview addSubview:label];

  UITextField *textField = [[UITextField alloc] init];
  textField.text = @"I am a text field";
  [scrollview addSubview:textField];

  UITextView *textView = [[UITextView alloc] init];
  textView.text = @"I am a text view";
  [scrollview addSubview:textView];

  UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
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

@end
