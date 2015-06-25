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

#import "FBSDKMessengerUtils.h"

// Keys to get App-specific info from mainBundle
static NSString *const FBPLISTAppIDKey = @"FacebookAppID";

NSString *FBSDKMessengerDefaultAppID(void)
{
  static NSString *defaultAppId = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultAppId = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBPLISTAppIDKey] copy];
  });

  return defaultAppId;
}

NSString *FBSDKMessengerDefaultAppIDURLScheme(void)
{
  return [NSString stringWithFormat:@"fb%@", FBSDKMessengerDefaultAppID()];
}

CGRect FBSDKMessengerRectMakeWithSizeCenteredInRect(CGSize size, CGRect rect) {
  CGPoint centerPoint = FBSDKMessengerRectGetMid(rect);
  CGPoint origin = CGPointMake(centerPoint.x - (size.width / 2.0),
                               centerPoint.y - (size.height / 2.0));
  CGRect centeredRect = FBSDKMessengerRectMakeWithOrigin(origin, size);
  return centeredRect;
}

CGPoint FBSDKMessengerRectGetMid(CGRect rect) {
  return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}


CGRect FBSDKMessengerRectMakeWithOrigin(CGPoint origin, CGSize size) {
  return CGRectMake(origin.x, origin.y, size.width, size.height);
}

NSString *FBSDKMessengerEncodingQueryURL(NSString *urlStr) {
  return [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
}
