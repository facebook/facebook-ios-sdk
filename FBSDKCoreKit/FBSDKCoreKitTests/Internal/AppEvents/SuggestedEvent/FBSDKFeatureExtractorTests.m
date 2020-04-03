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

#import "FBSDKFeatureExtractor.h"
#import "FBSDKModelManager.h"
#import "FBSDKViewHierarchyMacros.h"

@interface FBSDKFeatureExtractor ()
+ (BOOL)pruneTree:(NSMutableDictionary *)node
         siblings:(NSMutableArray *)siblings;

+ (float *)nonparseFeatures:(NSMutableDictionary *)node
                   siblings:(NSMutableArray *)siblings
                 screenname:(NSString *)screenname
             viewTreeString:(NSString *)viewTreeString;

+ (float *)parseFeatures:(NSMutableDictionary *)node;

+ (BOOL)isButton:(NSDictionary *)node;

+ (void)update:(NSDictionary *)node
          text:(NSMutableString *)buttonTextString
          hint:(NSMutableString *)buttonHintString;

+ (BOOL)foundIndicators:(NSArray *)indicators
               inValues:(NSArray *)values;

+ (float)regextMatch:(NSString *)pattern
                text:(NSString *)text;

@end

@interface FBSDKFeatureExtractorTests : XCTestCase {
  NSDictionary *_rules;
  NSDictionary *_viewHierarchy;
  NSDictionary *_interactedNode;
  NSArray *_siblings;
}
@end

@implementation FBSDKFeatureExtractorTests

- (void)setUp
{
  // load rules for classifying view text
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *filepath = [bundle pathForResource:@"FBSDKTextClassifyRules" ofType:@"json"];
  if (filepath.length > 0) {
    _rules = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfFile:filepath] options:0 error:nil];;
  }

  id _mockModelManager = OCMClassMock([FBSDKModelManager class]);
  OCMStub([_mockModelManager getRulesForKey:[OCMArg any]]).andReturn(_rules);
  [FBSDKFeatureExtractor loadRulesForKey:@"MTML"];

  _viewHierarchy = @{
    @"screenname": @"UITabBarController",
    @"view": @[
        @{
          @"classname": @"UIWindow",
          @"classtypebitmask": @"0",
          @"childviews": @[
              @{
                @"classname": @"UITabBarController",
                @"classtypebitmask": @"131072",
                @"childviews": @[
                    @{
                      @"classname": @"UINavigationController",
                      @"classtypebitmask": @"131072",
                      @"childviews": @[
                          @{
                            @"classname": @"CheckoutViewController",
                            @"classtypebitmask": @"131072",
                            @"childviews": @[
                                @{
                                  @"classname": @"UIStackView",
                                  @"classtypebitmask": @"0",
                                  @"childviews": @[
                                      @{
                                        @"classname": @"UILabel",
                                        @"classtypebitmask": @"1024",
                                        @"text": @"Order Summary",
                                      },
                                      @{
                                        @"classname": @"UIStackView",
                                        @"classtypebitmask": @"0",
                                        @"childviews": @[
                                            @{
                                              @"classname": @"UIView",
                                              @"classtypebitmask": @"0",
                                            },
                                            @{
                                              @"classname": @"UILabel",
                                              @"classtypebitmask": @"1024",
                                              @"text": @"Coffee 5",
                                            },
                                            @{
                                              @"classname": @"UILabel",
                                              @"classtypebitmask": @"Price: $5.99",
                                            },
                                        ]
                                      },
                                      @{
                                        @"classname": @"UIStackView",
                                        @"classtypebitmask": @"0",
                                        @"childviews": @[
                                            @{
                                              @"classname": @"UIView",
                                              @"classtypebitmask": @"0",
                                            },
                                            @{
                                              @"classname": @"UILabel",
                                              @"classtypebitmask": @"1024",
                                              @"text": @"Quantity",
                                            },
                                            @{
                                              @"classname": @"UILabel",
                                              @"classtypebitmask": @"1",
                                            },
                                        ]
                                      },
                                      @{
                                        @"classname": @"UITextField",
                                        @"classtypebitmask": @"2056",
                                        @"hint": @"Credit Card Credit Card",
                                      },
                                      @{
                                        @"classname": @"UITextField",
                                        @"classtypebitmask": @"2056",
                                        @"hint": @"Shipping Address Shipping Address",
                                      },
                                      @{
                                        @"classname": @"UIButton",
                                        @"classtypebitmask": @"24",
                                        @"is_interacted": @1,
                                        @"hint": @"Confirm Order",
                                      },
                                  ]
                                }
                            ]
                          }
                      ]
                    },
                    @{
                      @"classname": @"UITabBar",
                      @"classtypebitmask": @"0",
                    }
                ]
              }
          ]
        }
    ]
  };

  _interactedNode = @{
    @"classname": @"UIButton",
    @"classtypebitmask": @"24",
    @"is_interacted": @1,
    @"hint": @"Confirm Order",
  };

  _siblings = @[
      @{
        @"classname": @"UILabel",
        @"classtypebitmask": @"1024",
        @"text": @"Order Summary",
      },
      @{
        @"classname": @"UIStackView",
        @"classtypebitmask": @"0",
        @"childviews": @[
            @{
              @"classname": @"UIView",
              @"classtypebitmask": @"0",
            },
            @{
              @"classname": @"UILabel",
              @"classtypebitmask": @"1024",
              @"text": @"Coffee 5",
            },
            @{
              @"classname": @"UILabel",
              @"classtypebitmask": @"Price: $5.99",
            },
        ]
      },
      @{
        @"classname": @"UIStackView",
        @"classtypebitmask": @"0",
        @"childviews": @[
            @{
              @"classname": @"UIView",
              @"classtypebitmask": @"0",
            },
            @{
              @"classname": @"UILabel",
              @"classtypebitmask": @"1024",
              @"text": @"Quantity",
            },
            @{
              @"classname": @"UILabel",
              @"classtypebitmask": @"1",
            },
        ]
      },
      @{
        @"classname": @"UITextField",
        @"classtypebitmask": @"2056",
        @"hint": @"Credit Card Credit Card",
      },
      @{
        @"classname": @"UITextField",
        @"classtypebitmask": @"2056",
        @"hint": @"Shipping Address Shipping Address",
      },
      @{
        @"classname": @"UIButton",
        @"classtypebitmask": @"24",
        @"is_interacted": @1,
        @"hint": @"Confirm Order",
      },
  ];
}

- (void)testGetDenseFeature
{
  if (!_rules) {
    return;
  }

  float *denseFeature = [FBSDKFeatureExtractor getDenseFeatures:_viewHierarchy];

  // Get dense feature string
  NSMutableArray *denseFeatureArray = [NSMutableArray array];
  for (int i=0; i < 30; i++) {
    [denseFeatureArray addObject:[NSNumber numberWithFloat: denseFeature[i]]];
  }

  XCTAssertEqualObjects([denseFeatureArray componentsJoinedByString:@","], @"0,0,0,5,0,0,0,0,0,0,0,0,0,-1,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");
}

- (void)testGetTextFeature
{
  // Lowercase all text
  XCTAssertEqualObjects([FBSDKFeatureExtractor getTextFeature:@"Buy Buy Buy" withScreenName:@"BuyPage"], @"xctest | buypage, buy buy buy");
}

- (void)testPruneTree
{
  NSMutableArray *viewTree = [_viewHierarchy[VIEW_HIERARCHY_VIEW_KEY] mutableCopy];
  NSMutableArray *siblings = [NSMutableArray array];
  [FBSDKFeatureExtractor pruneTree:[viewTree[0] mutableCopy] siblings:siblings];
  XCTAssertEqualObjects([siblings copy], _siblings);
}

- (void)testNonparseFeature
{
  if (!_rules) {
    return;
  }

  NSString *viewTreeString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[_viewHierarchy[VIEW_HIERARCHY_VIEW_KEY] mutableCopy]
                                                                                            options:0
                                                                                              error:nil]
                                                   encoding:NSUTF8StringEncoding];
  float *nonParseFeature = [FBSDKFeatureExtractor nonparseFeatures:[_interactedNode mutableCopy]
                                                          siblings:[_siblings mutableCopy]
                                                        screenname:_viewHierarchy[VIEW_HIERARCHY_SCREEN_NAME_KEY]
                                                    viewTreeString:viewTreeString];

  // Get non-parsed feature string
  NSMutableArray *nonParseFeatureArray = [NSMutableArray array];
  for (int i=0; i < 30; i++) {
    [nonParseFeatureArray addObject:[NSNumber numberWithFloat: nonParseFeature[i]]];
  }

  XCTAssertEqualObjects([nonParseFeatureArray componentsJoinedByString:@","], @"0,0,0,5,0,0,0,0,0,0,0,0,0,-1,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");
}

- (void)testParseFeature
{
  if (!_rules) {
    return;
  }

  float *parseFeature = [FBSDKFeatureExtractor parseFeatures:[_viewHierarchy[VIEW_HIERARCHY_VIEW_KEY] mutableCopy][0]];

  // Get parsed feature string
  NSMutableArray *parseFeatureArray = [NSMutableArray array];
  for (int i=0; i < 30; i++) {
    [parseFeatureArray addObject:[NSNumber numberWithFloat: parseFeature[i]]];
  }

  XCTAssertEqualObjects([parseFeatureArray componentsJoinedByString:@","], @"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");
}

- (void)testIsButton
{
  NSDictionary *labelNode = @{
    @"classname": @"UILabel",
    @"classtypebitmask": @"1024",
    @"text": @"Coffee 5",
  };
  XCTAssertEqual([FBSDKFeatureExtractor isButton:_interactedNode], true);
  XCTAssertEqual([FBSDKFeatureExtractor isButton:labelNode], false);
}

- (void)testUpdateTextAndHint
{
  NSMutableString *buttonTextString = [NSMutableString string];
  NSMutableString *buttonHintString = [NSMutableString string];
  [FBSDKFeatureExtractor update:_interactedNode
                           text:buttonTextString
                           hint:buttonHintString];
  XCTAssertEqualObjects([buttonTextString copy], @"");
  XCTAssertEqualObjects([buttonHintString copy], @"confirm order ");
}

- (void)testFoundIndicators
{
  BOOL test1 = [FBSDKFeatureExtractor foundIndicators:@[@"phone", @"tel"]
                                             inValues:@[@"your phone number", @"111-111-1111"]];
  BOOL test2 = [FBSDKFeatureExtractor foundIndicators:@[@"phone", @"tel"]
                                             inValues:@[@"your email", @"test@fb.com"]];
  XCTAssertEqual(test1, true);
  XCTAssertEqual(test2, false);
}

- (void)testRegextMatch
{
  XCTAssertEqual([FBSDKFeatureExtractor regextMatch:@"(?i)(sign in)|login|signIn" text:@"click to sign in"], 1.0);
  XCTAssertEqual([FBSDKFeatureExtractor regextMatch:@"(?i)(sign in)|login|signIn" text:@"click to sign up"], 0.0);
}

@end
