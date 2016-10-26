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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKIntegrationTestCase.h"
#import "FBSDKTestBlocker.h"

@interface FBSDKImageDownloaderTests : FBSDKIntegrationTestCase

@end

@implementation FBSDKImageDownloaderTests

- (void)testImageCache
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];

  __block NSUInteger numRequests = 0;

  UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
  UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    if ([request.URL.path rangeOfString:@"favicon.ico"].location != NSNotFound) {
      return YES;
    } else {
      return NO;
    }
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    // count num requests in the response - ohttpstubs can call the test block
    // multiple times for the same request so we cannot count there accurately.
    numRequests++;
    return [OHHTTPStubsResponse responseWithData:UIImagePNGRepresentation(blank)
                                      statusCode:200
                                         headers:nil];
  }];

  [[FBSDKImageDownloader sharedInstance] removeAll];
  NSURL *url = [NSURL URLWithString:@"https://www.facebook.com/favicon.ico"];

  // we'll make 3 calls for the same image and make sure there are only 2 actual network requests.

  // call #1, ttl = 0 so it should definitely make a request.
  dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
  dispatch_async(aQueue, ^{
    [[FBSDKImageDownloader sharedInstance] downloadImageWithURL:url
                                                            ttl:0
                                                     completion:^(UIImage *image) {
                                                       [blocker signal];
                                                       XCTAssertNotNil(image);
                                                     }];
  });
    XCTAssertTrue([blocker waitWithTimeout:5], @"did not get callback.");
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  // call #2, ttl = 1 hour so it should not make a request.
  [[FBSDKImageDownloader sharedInstance] downloadImageWithURL:url
                                                          ttl:60*60
                                                   completion:^(UIImage *image) {
                                                     [blocker signal];
                                                     XCTAssertNotNil(image);
                                                   }];
  XCTAssertTrue([blocker waitWithTimeout:5], @"did not get callback.");
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  // call #3, ttl = 0 so it should definitely make a request again
  [[FBSDKImageDownloader sharedInstance] downloadImageWithURL:url
                                                          ttl:0
                                                   completion:^(UIImage *image) {
                                                     [blocker signal];
                                                     XCTAssertNotNil(image);
                                                   }];

  XCTAssertTrue([blocker waitWithTimeout:5], @"did not get callback.");
  XCTAssertEqual(2, numRequests, @"unexpected number of requests to download");
  [OHHTTPStubs removeAllStubs];
}

- (void)testImageCacheBadURL
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:2];
  __block NSUInteger numRequests = 0;
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    if ([request.URL.path rangeOfString:@"favicon.ico"].location != NSNotFound) {
      return YES;
    }
    else {
      return NO;
    }
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    numRequests++;
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:404
                                         headers:nil];
  }];
  NSURL *url = [NSURL URLWithString:@"https://www.facebook.com/favicon.ico"];
  [[FBSDKImageDownloader sharedInstance] downloadImageWithURL:url
                                                          ttl:0
                                                   completion:^(UIImage *image) {
                                                     [blocker signal];
                                                     XCTAssertNil(image);
                                                   }];
  // try twice.
  [[FBSDKImageDownloader sharedInstance] downloadImageWithURL:url
                                                          ttl:0
                                                   completion:^(UIImage *image) {
                                                     [blocker signal];
                                                     XCTAssertNil(image);
                                                   }];
  XCTAssertTrue([blocker waitWithTimeout:10], @"did not get 2 callbacks.");
  XCTAssertEqual(2, numRequests, @"unexpected number of requests to download");
  [OHHTTPStubs removeAllStubs];
}

@end
