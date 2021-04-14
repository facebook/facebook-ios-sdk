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

#import "FBSDKErrorRecoveryAttempter.h"

#import "FBSDKErrorRecoveryConfiguration.h"

@interface FBSDKTemporaryErrorRecoveryAttempter : FBSDKErrorRecoveryAttempter
@end

@implementation FBSDKTemporaryErrorRecoveryAttempter

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex completionHandler:(void (^)(BOOL didRecover))completionHandler
{
  @try {
    completionHandler(YES);
  } @catch (NSException *exception) {
    NSLog(@"Fail to complete error recovery. Exception reason: %@", exception.reason);
  }
}

@end

@implementation FBSDKErrorRecoveryAttempter

+ (instancetype)recoveryAttempterFromConfiguration:(FBSDKErrorRecoveryConfiguration *)configuration
{
  if (configuration.errorCategory == FBSDKGraphRequestErrorTransient) {
    return [FBSDKTemporaryErrorRecoveryAttempter new];
  } else if (configuration.errorCategory == FBSDKGraphRequestErrorOther) {
    return nil;
  }
  if ([configuration.recoveryActionName isEqualToString:@"login"]) {
    Class loginRecoveryAttmpterClass = NSClassFromString(@"_FBSDKLoginRecoveryAttempter");
    if (loginRecoveryAttmpterClass) {
      return [loginRecoveryAttmpterClass new];
    }
  }
  return nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)attemptRecoveryFromError:(NSError *)error
                     optionIndex:(NSUInteger)recoveryOptionIndex
                        delegate:(nullable id)delegate
              didRecoverSelector:(SEL)didRecoverSelector
                     contextInfo:(nullable void *)contextInfo
{
  [self attemptRecoveryFromError:error optionIndex:recoveryOptionIndex completionHandler:^(BOOL didRecover) {
    void (*callback)(id, SEL, BOOL, void *) = (void *)[delegate methodForSelector:didRecoverSelector];
    (*callback)(delegate, didRecoverSelector, didRecover, contextInfo);
  }];
}

#pragma clang diagnostic pop

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex completionHandler:(void (^)(BOOL didRecover))completionHandler
{
  // should be implemented by subclasses.
}

@end
