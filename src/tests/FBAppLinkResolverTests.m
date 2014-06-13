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
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSDictionary *queryParameters = [FBUtility queryParamsDictionaryFromFBURL:request.URL];
        askedForPhone = [queryParameters[@"fields"] rangeOfString:@"iphone"].location != NSNotFound;
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:nil
                                          statusCode:200
                                        responseTime:0
                                             headers:nil];
    }];

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPhone];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    assertThatBool(askedForPhone, is(equalToBool(YES)));
}

- (void)testUsesPhoneDataOnPhone
{
    [self stubAllResponsesWithResult:@{
                                   kAppLinkURLString : @{
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
                                           @"id": kAppLinkURLString
                                           }
                                   }];

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPhone];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    assertThat(link, is(notNilValue()));
    assertThat(link.sourceURL.absoluteString, is(equalTo(kAppLinkURLString)));
    assertThat(link.targets, contains(hasProperty(@"appStoreId", @"456"), hasProperty(@"appStoreId", @"123"), nil));
}

- (void)testAsksForPadDataOnPad
{
    __block BOOL askedForPad = NO;
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSDictionary *queryParameters = [FBUtility queryParamsDictionaryFromFBURL:request.URL];
        askedForPad = [queryParameters[@"fields"] rangeOfString:@"ipad"].location != NSNotFound;
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:nil
                                          statusCode:200
                                        responseTime:0
                                             headers:nil];
    }];

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPad];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    assertThatBool(askedForPad, is(equalToBool(YES)));
}

- (void)testUsesPadDataOnPad
{
    [self stubAllResponsesWithResult:@{
                                   kAppLinkURLString : @{
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
                                           @"id": kAppLinkURLString
                                           }
                                   }];

    FBAppLinkResolver *resolver = [[FBAppLinkResolver alloc] initWithUserInterfaceIdiom:UIUserInterfaceIdiomPad];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    assertThat(link, is(notNilValue()));
    assertThat(link.sourceURL.absoluteString, is(equalTo(kAppLinkURLString)));
    assertThat(link.targets, contains(hasProperty(@"appStoreId", @"456"), hasProperty(@"appStoreId", @"123"), nil));
}


- (void)testIgnoresAndroidData
{
    // We are not asking for it, but just make sure we ignore any non-iOS-platform data we get, to be safe.
    [self stubAllResponsesWithResult:@{
                                   kAppLinkURLString : @{
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
                                           @"id": kAppLinkURLString
                                           }
                                   }];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    assertThat(link, is(notNilValue()));
    assertThat(link.targets, contains(hasProperty(@"appStoreId", @"123"), nil));
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
    assertThat(link, is(notNilValue()));
    assertThat(link.sourceURL.absoluteString, is(equalTo(kAppLinkURLString)));
    assertThat(link.targets, isEmpty());
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
    assertThat(links, is(notNilValue()));
    assertThatUnsignedInteger(links.count, is(equalToUnsignedInteger(2)));

    assertThat([links[[NSURL URLWithString:kAppLinkURLString]] sourceURL].absoluteString, is(equalTo(kAppLinkURLString)));
    assertThat([links[[NSURL URLWithString:kAppLinkURL2String]] sourceURL].absoluteString, is(equalTo(kAppLinkURL2String)));
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
    assertThat(link, is(notNilValue()));
    assertThat(link.webURL.absoluteString, is(equalTo(kAppLinkURLString)));
}

- (void)testSetsFallbackIfSpecified
{
    [self stubAllResponsesWithResult:@{
                                       kAppLinkURLString : @{
                                               @"id": kAppLinkURLString,
                                               @"web": @{
                                                       @"url" : @"http://www.example.com/somethingelse",
                                                       @"should_fallback": @"true"
                                                       }
                                               }
                                       }];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    assertThat(link, is(notNilValue()));
    assertThat(link.webURL.absoluteString, is(equalTo(@"http://www.example.com/somethingelse")));
}

- (void)testUsesSourceAsFallbackIfSpecified
{
    [self stubAllResponsesWithResult:@{
                                       kAppLinkURLString : @{
                                               @"id": kAppLinkURLString,
                                               @"web": @{
                                                       @"should_fallback": @"true"
                                                       }
                                               }
                                       }];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    assertThat(link, is(notNilValue()));
    assertThat(link.webURL.absoluteString, is(equalTo(kAppLinkURLString)));
}

- (void)testSetsNoFallbackIfSpecified
{
    [self stubAllResponsesWithResult:@{
                                   kAppLinkURLString : @{
                                           @"id": kAppLinkURLString,
                                           @"web": @{
                                                   @"url" : @"http://www.example.com/somethingelse",
                                                   @"should_fallback": @"false"
                                                   }
                                           }
                                   }];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    assertThat(link, is(notNilValue()));
    assertThat(link.webURL.absoluteString, is(nilValue()));
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
    assertThat(link, is(nilValue()));

    NSError *error = task.error;
    assertThat(error, is(notNilValue()));
}

- (void)testResultsAreCachedAndCacheIsUsed
{
    __block NSUInteger callCount = 0;

    [self stubAllResponsesWithResult:@{
                                       kAppLinkURLString : @{
                                               @"iphone": @[
                                                       @{
                                                           @"app_name": @"Example",
                                                           @"app_store_id": @"456",
                                                           @"url": @"example://things/1234567890"
                                                           }
                                                       ],
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

    assertThatUnsignedInteger(callCount, is(equalToUnsignedInteger(expectedCallCount)));
}

- (void)testMixOfCachedAndUncached
{
    __block NSMutableDictionary *callCounts = [NSMutableDictionary dictionary];

    [self stubMatchingRequestsWithResponses:@{
                                              @"1234567890" : @{
                                                      kAppLinkURLString : @{
                                                              @"iphone": @[
                                                                      @{
                                                                          @"app_name": @"Example",
                                                                          @"app_store_id": @"456",
                                                                          @"url": @"example://things/1234567890"
                                                                          }
                                                                      ],
                                                              @"id": kAppLinkURLString
                                                              }
                                                      },
                                              @"0987654321" : @{
                                                      kAppLinkURL2String : @{
                                                              @"iphone": @[
                                                                      @{
                                                                          @"app_name": @"Example",
                                                                          @"app_store_id": @"456",
                                                                          @"url": @"example://things/1234567890"
                                                                          }
                                                                      ],
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

    assertThatUnsignedInteger(callCounts.count, is(equalToUnsignedInteger(1)));

    // Note: callCount is not necessarily 1, as the callback may be called multiple times during processing of the request.
    NSString *firstCallKey = callCounts.allKeys[0];
    NSUInteger expectedCallCount = [callCounts[firstCallKey] unsignedIntegerValue];

    // Now request them both; we expect the call count for kAppLinkURL to be unchanged.
    task = [resolver appLinksFromURLsInBackground:@[[NSURL URLWithString:kAppLinkURLString], [NSURL URLWithString:kAppLinkURL2String]]];
    [self waitForTaskOnMainThread:task];

    assertThatUnsignedInteger(callCounts.count, is(equalToUnsignedInteger(2)));
    assertThatUnsignedInteger([callCounts[firstCallKey] unsignedIntegerValue], is(equalToUnsignedInteger(expectedCallCount)));

    NSDictionary *links = task.result;
    assertThatUnsignedInteger(links.count, is(equalToUnsignedInteger(2)));
}

@end
