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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKAppLinkResolver.h"
#import "FBSDKTestCase.h"

static NSString *const kAppLinkURLString = @"http://example.com/1234567890";
static NSString *const kAppLinkURL2String = @"http://example.com/0987654321";
static NSString *const kAppLinksKey = @"app_links";
static NSString *const kIphoneKey = @"iphone";
static NSString *const kIpadKey = @"ipad";

@interface NSURL (FBSDKAppLinkResolverTests)

@property (nonatomic, readonly, strong) id queryParameters;

@end

@interface FBSDKAppLinkResolver (FBSDKAppLinkResolverTests)

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;
- (instancetype)initWithRequestBuilder:(FBSDKAppLinkResolverRequestBuilder *)builder;
- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom andRequestBuilder:(FBSDKAppLinkResolverRequestBuilder *)builder;

@end

@interface FBSDKAppLinkResolverTests : FBSDKTestCase
@end

@implementation FBSDKAppLinkResolverTests

#pragma mark - Mock requests

- (void)mockAppLinkRequestWithResult:(id)result
{
  [self mockAppLinkRequestWithResult:result error:nil idiomSpecificField:kIphoneKey];
}

- (void)mockAppLinkRequestWithError
{
  [self mockAppLinkRequestWithResult:@{@"error" : @{}}
                               error:[[NSError alloc]
                                      initWithDomain:FBSDKErrorDomain
                                      code:-1
                                      userInfo:nil]
                  idiomSpecificField:kIphoneKey];
}

- (void)mockAppLinkRequestWithResult:(id)result idiomSpecificField:(NSString *)field
{
  [self mockAppLinkRequestWithResult:result error:nil idiomSpecificField:field];
}

- (void)mockAppLinkRequestWithResult:(id)result error:(NSError *)error idiomSpecificField:(NSString *)field
{
  [self mockAppLinkRequestWithResult:result error:error idiomSpecificField:field andDo:nil];
}

- (void)mockAppLinkRequestWithResult:(id)result error:(NSError *)error idiomSpecificField:(NSString *)field andDo:(void (^_Nullable)(NSInvocation *))block
{
  [self stubGraphRequestWithResult:result error:error connection:nil];
  [self stubAppLinkResolverRequestBuilderWithIdiomSpecificField:field];

  OCMStub([self.appLinkResolverRequestBuilderMock requestForURLs:[OCMArg any]]).andReturn(self.graphRequestMock).andDo(block);
}

#pragma mark - test cases

- (void)testUsesPhoneDataOnPhone
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"usesPhoneDataOnPhone"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      kAppLinksKey : @{
        kIphoneKey : @[
          @{
            @"app_name" : @"Example",
            @"app_store_id" : @"456",
            @"url" : @"example://things/1234567890"
          }
        ],
        @"ios" : @[
          @{
            @"app_name" : @"Example",
            @"app_store_id" : @"123",
            @"url" : @"example://things/1234567890"
          }
        ],
      },
      @"id" : kAppLinkURLString
    }
  };

  [self mockAppLinkRequestWithResult:result idiomSpecificField:kIphoneKey];

  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPhone andRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.sourceURL.absoluteString, kAppLinkURLString);
     XCTAssertEqualObjects([link.targets[0] appStoreId], @"456");
     XCTAssertEqualObjects([link.targets[1] appStoreId], @"123");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testUsesPadDataOnPad
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"usesPadDataOnPad"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      kAppLinksKey : @{
        @"ipad" : @[
          @{
            @"app_name" : @"Example",
            @"app_store_id" : @"456",
            @"url" : @"example://things/1234567890"
          }
        ],
        @"ios" : @[
          @{
            @"app_name" : @"Example",
            @"app_store_id" : @"123",
            @"url" : @"example://things/1234567890"
          }
        ],
      },
      @"id" : kAppLinkURLString
    }
  };

  [self mockAppLinkRequestWithResult:result idiomSpecificField:kIpadKey];

  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPad andRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.sourceURL.absoluteString, kAppLinkURLString);
     XCTAssertEqualObjects([link.targets[0] appStoreId], @"456");
     XCTAssertEqualObjects([link.targets[1] appStoreId], @"123");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testIgnoresAndroidData
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"ignoresAndroidData"];
  [self stubClientTokenWith:@"clienttoken"];

  // We are not asking for it, but just make sure we ignore any non-iOS-platform data we get, to be safe.
  id result = @{
    kAppLinkURLString : @{
      kAppLinksKey : @{
        @"android" : @[
          @{
            @"app_name" : @"Example",
            @"package" : @"com.example.app",
            @"url" : @"example://things/1234567890"
          }
        ],
        @"ios" : @[
          @{
            @"app_name" : @"Example",
            @"app_store_id" : @"123",
            @"url" : @"example://things/1234567890"
          }
        ],
      },
      @"id" : kAppLinkURLString
    }
  };

  [self mockAppLinkRequestWithResult:result];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqualObjects([link.targets[0] appStoreId], @"123");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testHandlesNoTargets
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesNoTargets"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      @"id" : kAppLinkURLString
    }
  };

  [self mockAppLinkRequestWithResult:result];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.sourceURL.absoluteString, kAppLinkURLString);
     XCTAssertEqual(link.targets.count, 0);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testHandlesMultipleURLs
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesMultipleURLs"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      @"id" : kAppLinkURLString
    },
    kAppLinkURL2String : @{
      @"id" : kAppLinkURL2String
    }
  };

  [self mockAppLinkRequestWithResult:result];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinksFromURLs:@[[NSURL URLWithString:kAppLinkURLString], [NSURL URLWithString:kAppLinkURL2String]]
   handler:^(NSDictionary<NSURL *, FBSDKAppLink *> *_Nonnull links, NSError *_Nullable error) {
     XCTAssertNotNil(links);
     XCTAssertEqual(links.count, 2);
     XCTAssertEqual([links[[NSURL URLWithString:kAppLinkURLString]] sourceURL].absoluteString, kAppLinkURLString);
     XCTAssertEqual([links[[NSURL URLWithString:kAppLinkURL2String]] sourceURL].absoluteString, kAppLinkURL2String);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testSetsFallbackIfNotSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"setsFallbackIfNotSpecified"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      @"id" : kAppLinkURLString
    }
  };

  [self mockAppLinkRequestWithResult:result];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.webURL.absoluteString, kAppLinkURLString);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testSetsFallbackIfSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"setsFallbackIfSpecified"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      kAppLinksKey : @{
        @"web" : @{
          @"url" : @"http://www.example.com/somethingelse",
          @"should_fallback" : @"true"
        }
      },
      @"id" : kAppLinkURLString
    }
  };

  [self mockAppLinkRequestWithResult:result];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqualObjects(link.webURL.absoluteString, @"http://www.example.com/somethingelse");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testUsesSourceAsFallbackIfSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"usesSourceAsFallbackIfSpecified"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      kAppLinksKey : @{
        @"web" : @{
          @"should_fallback" : @"true"
        }
      },
      @"id" : kAppLinkURLString,
    }
  };

  [self mockAppLinkRequestWithResult:result];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.webURL.absoluteString, kAppLinkURLString);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testSetsNoFallbackIfSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"setsNoFallbackIfSpecified"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      kAppLinksKey : @{
        @"web" : @{
          @"url" : @"http://www.example.com/somethingelse",
          @"should_fallback" : @"false"
        }
      },
      @"id" : kAppLinkURLString
    }
  };

  [self mockAppLinkRequestWithResult:result];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertNil(link.webURL.absoluteString);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testHandlesError
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesError"];
  [self stubClientTokenWith:@"clienttoken"];

  [self mockAppLinkRequestWithError];
  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link, NSError *_Nullable error) {
     XCTAssertNil(link);
     XCTAssertNotNil(error);
     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

- (void)testResultsAreCachedAndCacheIsUsed
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesCache"];
  [self stubClientTokenWith:@"clienttoken"];

  id result = @{
    kAppLinkURLString : @{
      kAppLinksKey : @{
        @"iphone" : @[
          @{
            @"app_name" : @"Example",
            @"app_store_id" : @"456",
            @"url" : @"example://things/1234567890"
          }
        ],
      },
      @"id" : kAppLinkURLString
    }
  };

  // We can change the approach and do OCMVerify(exactly(1), [_mockRequestBuilder requestForURLs]);
  // in the inner block of the double call instead of using this counter.
  __block int callCount = 0;
  [self mockAppLinkRequestWithResult:result error:nil idiomSpecificField:kIphoneKey andDo:^(NSInvocation *invocation) {
    callCount++;
  }];

  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithRequestBuilder:self.appLinkResolverRequestBuilderMock];

  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink *_Nullable link1, NSError *_Nullable error1) {
     [resolver
      appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
      handler:^(FBSDKAppLink *_Nullable link2, NSError *_Nullable error2) {
        XCTAssertEqual(callCount, 1);
        [expectation fulfill];
      }];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

@end
