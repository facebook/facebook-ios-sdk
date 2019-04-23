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
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBSDKAppLinkResolver.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKSettings.h"

static NSString *const kAppLinkURLString = @"http://example.com/1234567890";
static NSString *const kAppLinkURL2String = @"http://example.com/0987654321";
static NSString *const kAppLinksKey = @"app_links";

typedef void (^HTTPStubCallback)(NSURLRequest *request);
typedef _Nullable id (^StringURLBlock)(NSString *urlString);

@interface NSURL (FBSDKAppLinkResolverTests)

@property (nonatomic, readonly, strong) id queryParameters;

@end

@interface FBSDKAppLinkResolver (FBSDKAppLinkResolverTests)

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

@end

@interface FBSDKAppLinkResolverTests : XCTestCase
@end

@implementation FBSDKAppLinkResolverTests
{
  id _mockNSBundle;
}

#pragma mark - HTTP stubbing helpers

- (void)stubAllResponsesWithResult:(id)result
{
  [self stubAllResponsesWithResult:result statusCode:200];
}

- (void)stubAllResponsesWithResult:(id)result
                        statusCode:(int)statusCode
{
  [self stubAllResponsesWithResult:result statusCode:statusCode callback:nil];
}

- (void)stubAllResponsesWithResult:(id)result
                        statusCode:(int)statusCode
                          callback:(HTTPStubCallback)callback
{
  return [self stubMatchingRequestsWithResponses:@{@"" : result}
                                      statusCode:statusCode
                                        callback:callback];
}

- (void)stubMatchingRequestsWithResponses:(NSDictionary<NSString *, id> *)requestsAndResponses
                               statusCode:(int)statusCode
                                 callback:(HTTPStubCallback)callback
{
  StringURLBlock matchingKey = ^id (NSString *urlString) {
    for (NSString *substring in requestsAndResponses.allKeys) {
      // The first @"" always matches
      if (substring.length == 0 ||
          [urlString rangeOfString:substring].location != NSNotFound) {
        return substring;
      }
    }
    return nil;
  };

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    if (callback) {
      callback(request);
    }

    return matchingKey(request.URL.absoluteString) != nil;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    id result = requestsAndResponses[matchingKey(request.URL.absoluteString)];
    NSData *data = [[FBSDKBasicUtility JSONStringForObject:result
                                                     error:NULL
                                      invalidObjectHandler:NULL] dataUsingEncoding:NSUTF8StringEncoding];

    return [OHHTTPStubsResponse responseWithData:data
                                      statusCode:statusCode
                                         headers:nil];
  }];
}

#pragma mark - test cases

- (void)setUp
{
  _mockNSBundle = [FBSDKCoreKitTestUtility mainBundleMock];
}

/*
- (void)testAsksForPhoneDataOnPhone
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"asksForPhoneDataOnPhone"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  __block BOOL askedForPhone = NO;
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSDictionary<NSString *, NSString *> *queryParameters =
     [FBSDKInternalUtility dictionaryFromFBURL:request.URL];
    askedForPhone = [queryParameters[@"fields"] rangeOfString:@"iphone"].location != NSNotFound;
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPhone];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable appLink, NSError * _Nullable error) {
     XCTAssertTrue(askedForPhone);
     [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testUsesPhoneDataOnPhone
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"usesPhoneDataOnPhone"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       kAppLinksKey: @{
                                         @"iphone": @[
                                           @{
                                             @"app_name": @"Example",
                                             @"app_store_id": @"456",
                                             @"url": @"example://things/1234567890"
                                           }
                                         ],
                                         @"ios": @[
                                           @{
                                             @"app_name": @"Example",
                                             @"app_store_id": @"123",
                                             @"url": @"example://things/1234567890"
                                           }
                                         ],
                                       },
                                       @"id": kAppLinkURLString
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPhone];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {

     XCTAssertNotNil(link);
     XCTAssertEqual(link.sourceURL.absoluteString, kAppLinkURLString);
     XCTAssertEqualObjects([link.targets[0] appStoreId], @"456");
     XCTAssertEqualObjects([link.targets[1] appStoreId], @"123");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testAsksForPadDataOnPad
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"asksForPadDataOnPad"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  __block BOOL askedForPad = NO;
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSDictionary<NSString *, NSString *> *queryParameters =
     [FBSDKInternalUtility dictionaryFromFBURL:request.URL];
    // do an "OR" because we only need to verify we asked for it once (in cases where unrelated network requests
    // were resetting the flag incorrectly back to NO).
    askedForPad |= [queryParameters[@"fields"] rangeOfString:@"ipad"].location != NSNotFound;
    return YES;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPad];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertTrue(askedForPad);
     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testUsesPadDataOnPad
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"usesPadDataOnPad"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       kAppLinksKey: @{
                                         @"ipad": @[
                                           @{
                                             @"app_name": @"Example",
                                             @"app_store_id": @"456",
                                             @"url": @"example://things/1234567890"
                                           }
                                         ],
                                         @"ios": @[
                                           @{
                                             @"app_name": @"Example",
                                             @"app_store_id": @"123",
                                             @"url": @"example://things/1234567890"
                                           }
                                         ],
                                       },
                                       @"id": kAppLinkURLString
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [[FBSDKAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPad];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.sourceURL.absoluteString, kAppLinkURLString);
     XCTAssertEqualObjects([link.targets[0] appStoreId], @"456");
     XCTAssertEqualObjects([link.targets[1] appStoreId], @"123");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}


- (void)testIgnoresAndroidData
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"ignoresAndroidData"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  // We are not asking for it, but just make sure we ignore any non-iOS-platform data we get, to be safe.
  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       kAppLinksKey: @{
                                         @"android": @[
                                           @{
                                             @"app_name": @"Example",
                                             @"package": @"com.example.app",
                                             @"url": @"example://things/1234567890"
                                           }
                                         ],
                                         @"ios": @[
                                           @{
                                             @"app_name": @"Example",
                                             @"app_store_id": @"123",
                                             @"url": @"example://things/1234567890"
                                           }
                                         ],
                                       },
                                       @"id": kAppLinkURLString
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqualObjects([link.targets[0] appStoreId], @"123");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testHandlesNoTargets
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesNoTargets"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       @"id": kAppLinkURLString
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.sourceURL.absoluteString, kAppLinkURLString);
     XCTAssertEqual(link.targets.count, 0);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testHandlesMultipleURLs
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesMultipleURLs"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       @"id": kAppLinkURLString
                                     },
                                     kAppLinkURL2String : @{
                                       @"id": kAppLinkURL2String
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinksFromURLs:@[[NSURL URLWithString:kAppLinkURLString], [NSURL URLWithString:kAppLinkURL2String]]
   handler:^(NSDictionary<NSURL *,FBSDKAppLink *> * _Nonnull links, NSError * _Nullable error) {
     XCTAssertNotNil(links);
     XCTAssertEqual(links.count, 2);
     XCTAssertEqual([links[[NSURL URLWithString:kAppLinkURLString]] sourceURL].absoluteString, kAppLinkURLString);
     XCTAssertEqual([links[[NSURL URLWithString:kAppLinkURL2String]] sourceURL].absoluteString, kAppLinkURL2String);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testSetsFallbackIfNotSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"setsFallbackIfNotSpecified"];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       @"id": kAppLinkURLString
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.webURL.absoluteString, kAppLinkURLString);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testSetsFallbackIfSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"setsFallbackIfSpecified"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       kAppLinksKey : @{
                                         @"web": @{
                                           @"url" : @"http://www.example.com/somethingelse",
                                           @"should_fallback": @"true"
                                         }
                                       },
                                       @"id": kAppLinkURLString
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqualObjects(link.webURL.absoluteString, @"http://www.example.com/somethingelse");

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testUsesSourceAsFallbackIfSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"usesSourceAsFallbackIfSpecified"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       kAppLinksKey: @{
                                         @"web": @{
                                           @"should_fallback": @"true"
                                         }
                                       },
                                       @"id": kAppLinkURLString,
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertEqual(link.webURL.absoluteString, kAppLinkURLString);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testSetsNoFallbackIfSpecified
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"setsNoFallbackIfSpecified"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       kAppLinksKey : @{
                                         @"web": @{
                                           @"url" : @"http://www.example.com/somethingelse",
                                           @"should_fallback": @"false"
                                         }
                                       },
                                       @"id": kAppLinkURLString
                                     }
                                   }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNotNil(link);
     XCTAssertNil(link.webURL.absoluteString);

     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testHandlesError
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesError"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  // We are not asking for it, but just make sure we ignore any non-iOS-platform data we get, to be safe.
  [self stubAllResponsesWithResult:@{
                                     @"error" : @{}
                                   }
                        statusCode:404];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link, NSError * _Nullable error) {
     XCTAssertNil(link);
     XCTAssertNotNil(error);
     [expectation fulfill];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testResultsAreCachedAndCacheIsUsed
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"handlesCache"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  __block NSUInteger callCount = 0;

  [self stubAllResponsesWithResult:@{
                                     kAppLinkURLString : @{
                                       kAppLinksKey : @{
                                         @"iphone": @[
                                           @{
                                             @"app_name": @"Example",
                                             @"app_store_id": @"456",
                                             @"url": @"example://things/1234567890"
                                           }
                                         ],
                                       },
                                       @"id": kAppLinkURLString
                                     }
                                   }
                        statusCode:200
                          callback:^(NSURLRequest *request) {
                            ++callCount;
                          }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable link1, NSError * _Nullable error1) {
     // Note: callCount is not necessarily 1, as the callback may be called multiple times during processing of the request.
     NSUInteger expectedCallCount = callCount;

     [resolver
      appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
      handler:^(FBSDKAppLink * _Nullable link2, NSError * _Nullable error2) {
        XCTAssertEqual(callCount, expectedCallCount);
        [expectation fulfill];
      }];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

/*
- (void)testMixOfCachedAndUncached
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"mixOfCachedAndUncached"];

  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setClientToken:@"clienttoken"];

  __block NSMutableDictionary<NSString *, NSNumber *> *callCounts =
   [NSMutableDictionary dictionary];

  [self stubMatchingRequestsWithResponses:@{
                                            @"1234567890" : @{
                                              kAppLinkURLString : @{
                                                kAppLinksKey : @{
                                                  @"iphone": @[
                                                    @{
                                                      @"app_name": @"Example",
                                                      @"app_store_id": @"456",
                                                      @"url": @"example://things/1234567890"
                                                    }
                                                  ],
                                                },
                                                @"id": kAppLinkURLString
                                              }
                                            },
                                            @"0987654321" : @{
                                              kAppLinkURL2String : @{
                                                kAppLinksKey : @{
                                                  @"iphone": @[
                                                    @{
                                                      @"app_name": @"Example",
                                                      @"app_store_id": @"456",
                                                      @"url": @"example://things/1234567890"
                                                    }
                                                  ],
                                                },
                                                @"id": kAppLinkURL2String
                                              }
                                            }
                                          }
                               statusCode:200
                                 callback:^(NSURLRequest *request) {
                                   NSUInteger callCount = callCounts[request.URL.absoluteString].unsignedIntegerValue;
                                   ++callCount;
                                   callCounts[request.URL.absoluteString] = @(callCount);
                                 }];

  FBSDKAppLinkResolver *resolver = [FBSDKAppLinkResolver resolver];

  // Prime the cache with kAppLinkURL
  [resolver
   appLinkFromURL:[NSURL URLWithString:kAppLinkURLString]
   handler:^(FBSDKAppLink * _Nullable appLink, NSError * _Nullable error1) {
     XCTAssertEqual(callCounts.count, 1);

     // Note: callCount is not necessarily 1, as the callback may be called multiple times during processing of the request.
     NSString *firstCallKey = callCounts.allKeys[0];
     NSUInteger expectedCallCount = callCounts[firstCallKey].unsignedIntegerValue;

     // Now request them both; we expect the call count for kAppLinkURL to be unchanged.
     [resolver
      appLinksFromURLs:@[[NSURL URLWithString:kAppLinkURLString], [NSURL URLWithString:kAppLinkURL2String]]
      handler:^(NSDictionary<NSURL *,FBSDKAppLink *> * _Nonnull links, NSError * _Nullable error2) {
        XCTAssertEqual(callCounts.count, 2);
        XCTAssertEqual([callCounts[firstCallKey] unsignedIntegerValue], expectedCallCount);

        XCTAssertEqual(links.count, 2);
        [expectation fulfill];
     }];
   }];

  [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
  }];
  [FBSDKSettings setClientToken:nil];
}
*/

@end
