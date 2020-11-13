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

#import "FBSDKIDToken.h"

#import <Foundation/Foundation.h>

#if SWIFT_PACKAGE
@import FBSDKCoreKit;
#else
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#endif

#ifdef FBSDKCOCOAPODS
 #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
 #import "FBSDKCoreKit+Internal.h"
#endif

@implementation FBSDKIDToken

- (instancetype)initWithTokenString:(NSString *)idTokenString
{
  if (!idTokenString || idTokenString.length == 0) {
    return nil;
  }

  NSArray *segments = [idTokenString componentsSeparatedByString:@"."];
  if (segments.count != 3) {
    return nil;
  }

  if (self = [super init]) {
    NSString *encodedClaims = [FBSDKTypeUtility array:segments objectAtIndex:1];

    // TODO(T78739428): verify signature

    [self setClaimsWithEncodedString:encodedClaims];
  }

  return self;
}

- (void)setClaimsWithEncodedString:(NSString *)encodedClaims
{
  NSError *error;
  NSData *claimsData = [FBSDKBase64 decodeAsData:encodedClaims];

  if (claimsData) {
    NSDictionary *decodedClaims = [FBSDKTypeUtility JSONObjectWithData:claimsData options:0 error:&error];
    if (!error) {
      // TODO(T78739428): verify claims

      _claims = decodedClaims;
    }
  }
}

#pragma mark - Test methods

#if DEBUG

+ (instancetype)emptyInstance
{
  return [super new];
}

#endif

@end
