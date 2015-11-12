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
#import "FBSDKIntegrationTestCase.h"

#import <OCMock/OCMock.h>

#import <FBSDKCoreKit/FBSDKTestUsersManager.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKTestBlocker.h"

static NSString *const FBSDKPLISTTestAppIDKey = @"IOS_SDK_TEST_APP_ID";
static NSString *const FBSDKPLISTTestAppSecretKey = @"IOS_SDK_TEST_APP_SECRET";
static NSString *const FBSDKPLISTTestAppClientTokenKey = @"IOS_SDK_TEST_CLIENT_TOKEN";

static NSString *g_AppID;
static NSString *g_AppSecret;
static NSString *g_AppClientToken;
static FBSDKTestUsersManager *g_testUsersManager;
static id g_mockNSBundle;

@implementation FBSDKIntegrationTestCase

+ (void)setUp {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    g_AppID = [environment objectForKey:FBSDKPLISTTestAppIDKey];
    g_AppSecret = [environment objectForKey:FBSDKPLISTTestAppSecretKey];
    g_AppClientToken= [environment objectForKey:FBSDKPLISTTestAppClientTokenKey];
    if (g_AppID.length == 0 || g_AppSecret.length == 0 || g_AppClientToken.length == 0) {
      [[NSException exceptionWithName:NSInternalInconsistencyException
                               reason:
        @"Integration Tests cannot be run. "
        @"Missing App ID or App Secret, or Client Token in Build Settings. "
        @"You can set this in an xcconfig file containing your unit-testing Facebook "
        @"Application's ID and Secret in this format:\n"
        @"\tIOS_SDK_TEST_APP_ID = // your app ID, e.g.: 1234567890\n"
        @"\tIOS_SDK_TEST_APP_SECRET = // your app secret, e.g.: 1234567890abcdef\n"
        @"\tIOS_SDK_TEST_CLIENT_TOKEN = // your app client token, e.g.: 1234567890abcdef\n"
        @"Do NOT release your app secret in your app. "
        @"To create a Facebook AppID, visit https://developers.facebook.com/apps"
                             userInfo:nil]
       raise];
    }
    [FBSDKSettings setAppID:g_AppID];
    g_testUsersManager = [FBSDKTestUsersManager sharedInstanceForAppID:g_AppID appSecret:g_AppSecret];
  });
  // swizzle out mainBundle - XCTest returns the XCTest program bundle instead of the target,
  // and our keychain code is coded against mainBundle.
  g_mockNSBundle = [OCMockObject niceMockForClass:[NSBundle class]];
  NSBundle *correctMainBundle = [NSBundle bundleForClass:[self class]];
  [[[[g_mockNSBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];
}

+ (void)tearDown
{
  [g_mockNSBundle stopMocking];
  g_mockNSBundle = nil;
}

#pragma mark - Properties
- (NSString *)testAppID{
  return g_AppID;
}

- (NSString *)testAppClientToken {
  return g_AppClientToken;
}

- (NSString *)testAppSecret {
  return g_AppSecret;
}

- (NSString *)testAppToken {
  return [NSString stringWithFormat:@"%@|%@", g_AppID, g_AppSecret];
}

#pragma mark - Methods

- (void)clearUserDefaults {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary *dict = [defaults dictionaryRepresentation];
  for (id key in dict) {
    [defaults removeObjectForKey:key];
  }
  [defaults synchronize];
}

- (UIImage *)createSquareTestImage:(int)size
{
  CGDataProviderSequentialCallbacks providerCallbacks;
  memset(&providerCallbacks, 0, sizeof(providerCallbacks));
  providerCallbacks.getBytes = getPixels;

  CGDataProviderRef provider = CGDataProviderCreateSequential(NULL, &providerCallbacks);
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

  int width = size;
  int height = size;
  int bitsPerComponent = 8;
  int bitsPerPixel = 8;
  int bytesPerRow = width * (bitsPerPixel/8);

  CGImageRef cgImage = CGImageCreate(width,
                                     height,
                                     bitsPerComponent,
                                     bitsPerPixel,
                                     bytesPerRow,
                                     colorSpace,
                                     kCGBitmapByteOrderDefault,
                                     provider,
                                     NULL,
                                     NO,
                                     kCGRenderingIntentDefault);

  UIImage *image = [UIImage imageWithCGImage:cgImage];

  CGColorSpaceRelease(colorSpace);
  CGDataProviderRelease(provider);
  CGImageRelease(cgImage);

  return image;
}

static size_t getPixels(void *info, void *buffer, size_t count) {
  char *c = buffer;
  for (int i = 0; i < count; ++i) {
    *c = arc4random() % 256;
  }
  return count;
}

- (FBSDKAccessToken *) getTokenWithPermissions:(NSSet *)permissions {
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block FBSDKAccessToken *token = nil;
  [g_testUsersManager requestTestAccountTokensWithArraysOfPermissions:(permissions ? @[permissions] : nil)
                                                     createIfNotFound:YES completionHandler:^(NSArray *tokens, NSError *error) {
                                                       XCTAssertNil(error, @"unexpected error trying to get test user");
                                                       token = tokens[0];
                                                       [blocker signal];
                                                     }];
  XCTAssertTrue([blocker waitWithTimeout:15], @"timeout - failed to fetch test user.");
  return token;
}

- (FBSDKTestUsersManager *)testUsersManager {
  return g_testUsersManager;
}

@end
