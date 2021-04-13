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

#import "FBSDKDeviceLoginCodeInfo+Internal.h"

#ifdef FBSDKCOCOAPODS
 #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
 #import "FBSDKCoreKit+Internal.h"
#endif

@implementation FBSDKDeviceLoginCodeInfo

- (instancetype)initWithIdentifier:(NSString *)identifier
                         loginCode:(NSString *)loginCode
                   verificationURL:(NSURL *)verificationURL
                    expirationDate:(NSDate *)expirationDate
                   pollingInterval:(NSUInteger)pollingInterval
{
  if ((self = [super init])) {
    NSString *validIdentifier = [FBSDKTypeUtility coercedToStringValue:identifier];
    NSString *validLoginCode = [FBSDKTypeUtility coercedToStringValue:loginCode];

    _identifier = validIdentifier == nil || validIdentifier.length == 0 ? nil : [identifier copy];
    _loginCode = validLoginCode == nil || validLoginCode.length == 0 ? nil : [loginCode copy];
    _verificationURL = [FBSDKTypeUtility URLValue:[verificationURL copy]];
    _expirationDate = [expirationDate isKindOfClass:NSDate.class] ? [expirationDate copy] : nil;
    _pollingInterval = pollingInterval;
  }
  return self;
}

@end
