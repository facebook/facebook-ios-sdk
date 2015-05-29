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

@class FBSDKAccessToken;
@class FBSDKTestUsersManager;

@interface NSString(FBSDKAppEventsIntegrationTests)
- (NSUInteger)countOfSubstring:(NSString *)substring;
@end

@implementation NSString(FBSDKAppEventsIntegrationTests)
- (NSUInteger)countOfSubstring:(NSString *)substring {
  NSUInteger count = 0;
  NSUInteger index = 0;
  NSRange r = [self rangeOfString:substring options:0 range:NSMakeRange(index, self.length - index -1)];
  while (r.location != NSNotFound) {
    count++;
    index = r.location+1;
    r = [self rangeOfString:substring options:0 range:NSMakeRange(index, self.length - index -1)];
  }
  return count;
}
@end

@interface FBSDKIntegrationTestCase : XCTestCase

@property (readonly, copy) NSString *testAppID;
@property (readonly, copy) NSString *testAppClientToken;
@property (readonly, copy) NSString *testAppSecret;
@property (readonly, copy) NSString *testAppToken;

// removes all keys from user defaults
- (void)clearUserDefaults;

// creates a random test image.
- (UIImage *)createSquareTestImage:(int)size;

// helper method to get single test user with desired permissions.
- (FBSDKAccessToken *)getTokenWithPermissions:(NSSet *)permissions;

// get the test manager (i.e., if you need multiple tokens at once).
- (FBSDKTestUsersManager *)testUsersManager;


@end
