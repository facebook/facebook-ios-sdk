/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Bolts/Bolts.h>

#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBAppLinkResolver.h"
#import "FBTests.h"
#import "FBUtility.h"

static NSString *const kAppLinkURLString = @"http://example.com/1234567890";
static NSString *const kAppLinkURL2String = @"http://example.com/0987654321";
static NSString *const kAppLinksKey = @"app_links";

@interface NSURL (FBAppLinkResolverTests)

- (id)queryParameters;

@end

@interface FBAppLinkResolver (FBAppLinkResolverTests)

- (id)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

@end

@interface FBAppLinkResolverTests : FBTests
@end

@implementation FBAppLinkResolverTests

- (void)waitForTaskOnMainThread:(BFTask *)task
{
    while (!task.isCompleted) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)testAsksForPhoneDataOnPhone
{
    __block BOOL askedForPhone = NO;
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSDictionary *queryParameters = [FBUtility queryParamsDictionaryFromFBURL:request.URL];
        askedForPhone = [queryParameters[@"fields"] rangeOfString:@"iphone"].location != NSNotFound;
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data]
                                          statusCode:200
                                             headers:nil];
    }];

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPhone];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    XCTAssertTrue(askedForPhone);
}

- (void)testUsesPhoneDataOnPhone
{
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

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPhone];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    XCTAssertNotNil(link);
    XCTAssertTrue([link.sourceURL.absoluteString isEqualToString:kAppLinkURLString]);
    XCTAssertTrue([link.targets indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:@"appStoreId"] isEqualToString:@"456"]) {
            return true;
        }
        return NO;
    }] != NSNotFound);
    XCTAssertTrue([link.targets indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:@"appStoreId"] isEqualToString:@"123"]) {
            return true;
        }
        return NO;
    }] != NSNotFound);
}

- (void)testAsksForPadDataOnPad
{
    __block BOOL askedForPad = NO;
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSDictionary *queryParameters = [FBUtility queryParamsDictionaryFromFBURL:request.URL];
        askedForPad = [queryParameters[@"fields"] rangeOfString:@"ipad"].location != NSNotFound;
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data]
                                          statusCode:200
                                             headers:nil];
    }];

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPad];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    XCTAssertTrue(askedForPad);
}

- (void)testUsesPadDataOnPad
{
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

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPad];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    XCTAssertNotNil(link);
    XCTAssertTrue([link.sourceURL.absoluteString isEqualToString:kAppLinkURLString]);
    XCTAssertTrue([link.targets indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:@"appStoreId"] isEqualToString:@"456"]) {
            return true;
        }
        return NO;
    }] != NSNotFound);
    XCTAssertTrue([link.targets indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:@"appStoreId"] isEqualToString:@"123"]) {
            return true;
        }
        return NO;
    }] != NSNotFound);
}


- (void)testIgnoresAndroidData
{
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

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    XCTAssertNotNil(link);
    XCTAssertTrue([link.targets indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:@"appStoreId"] isEqualToString:@"123"]) {
            return true;
        }
        return NO;
    }] != NSNotFound);
}

- (void)testHandlesNoTargets
{
    [self stubAllResponsesWithResult:@{
                                   kAppLinkURLString : @{
                                           @"id": kAppLinkURLString
                                           }
                                   }];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    XCTAssertNotNil(link);
    XCTAssertTrue([link.sourceURL.absoluteString isEqualToString:kAppLinkURLString]);
    XCTAssertTrue(link.targets.count == 0);
}

- (void)testHandlesMultipleURLs
{
    [self stubAllResponsesWithResult:@{
                                   kAppLinkURLString : @{
                                           @"id": kAppLinkURLString
                                           },
                                   kAppLinkURL2String : @{
                                           @"id": kAppLinkURL2String
                                           }
                                   }];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinksFromURLsInBackground:@[[NSURL URLWithString:kAppLinkURLString], [NSURL URLWithString:kAppLinkURL2String]]];
    [self waitForTaskOnMainThread:task];

    NSDictionary *links = task.result;
    XCTAssertNotNil(links);
    XCTAssertEqual(2, links.count);
    XCTAssertEqualObjects(kAppLinkURLString, [links[[NSURL URLWithString:kAppLinkURLString]] sourceURL].absoluteString);
    XCTAssertEqualObjects((kAppLinkURL2String), [links[[NSURL URLWithString:kAppLinkURL2String]] sourceURL].absoluteString);
}

- (void)testSetsFallbackIfNotSpecified
{
    [self stubAllResponsesWithResult:@{
                                   kAppLinkURLString : @{
                                           @"id": kAppLinkURLString
                                           }
                                   }];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;

    XCTAssertNotNil(link);
    XCTAssertEqualObjects(kAppLinkURLString, link.webURL.absoluteString);
}

- (void)testSetsFallbackIfSpecified
{
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

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    XCTAssertNotNil(link);
    XCTAssertTrue([link.webURL.absoluteString isEqualToString:@"http://www.example.com/somethingelse"]);
}

- (void)testUsesSourceAsFallbackIfSpecified
{
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

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;

    XCTAssertNotNil(link);
    XCTAssertEqualObjects(kAppLinkURLString, link.webURL.absoluteString);
}

- (void)testSetsNoFallbackIfSpecified
{
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

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    XCTAssertNotNil(link);
    XCTAssertNil(link.webURL.absoluteString);
}

- (void)testHandlesError
{
    // We are not asking for it, but just make sure we ignore any non-iOS-platform data we get, to be safe.
    [self stubAllResponsesWithResult:@{
                                   @"error" : @{}
                                   }
                      statusCode:404];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    XCTAssertNil(link);

    NSError *error = task.error;
    XCTAssertNotNil(error);
}

- (void)testResultsAreCachedAndCacheIsUsed
{
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


    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    // Note: callCount is not necessarily 1, as the callback may be called multiple times during processing of the request.
    NSUInteger expectedCallCount = callCount;

    task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    XCTAssertEqual(expectedCallCount, callCount);
}

- (void)testMixOfCachedAndUncached
{
    __block NSMutableDictionary *callCounts = [NSMutableDictionary dictionary];

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
                                NSUInteger callCount = [callCounts[request.URL.absoluteString] unsignedIntegerValue];
                                ++callCount;
                                callCounts[request.URL.absoluteString] = [NSNumber numberWithUnsignedInteger:callCount];
                            }];


    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    // Prime the cache with kAppLinkURL
    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    XCTAssertEqual(1, callCounts.count);

    // Note: callCount is not necessarily 1, as the callback may be called multiple times during processing of the request.
    NSString *firstCallKey = callCounts.allKeys[0];
    NSUInteger expectedCallCount = [callCounts[firstCallKey] unsignedIntegerValue];

    // Now request them both; we expect the call count for kAppLinkURL to be unchanged.
    task = [resolver appLinksFromURLsInBackground:@[[NSURL URLWithString:kAppLinkURLString], [NSURL URLWithString:kAppLinkURL2String]]];
    [self waitForTaskOnMainThread:task];

    XCTAssertEqual(2, callCounts.count);
    XCTAssertEqual(expectedCallCount,[callCounts[firstCallKey] unsignedIntegerValue]);

    NSDictionary *links = task.result;
    XCTAssertEqual(2, links.count);
}

@end
