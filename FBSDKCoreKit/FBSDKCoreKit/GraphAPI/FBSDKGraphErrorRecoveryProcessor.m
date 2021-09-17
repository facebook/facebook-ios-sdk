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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKGraphErrorRecoveryProcessor.h"

 #import "FBSDKAccessToken+AccessTokenProtocols.h"
 #import "FBSDKErrorRecoveryAttempter.h"
 #import "FBSDKGraphRequestProtocol.h"

@interface FBSDKGraphErrorRecoveryProcessor ()

@property (nonatomic, readonly) NSString *accessToken;
@property (nullable, nonatomic, readonly, weak) id<FBSDKGraphErrorRecoveryProcessorDelegate> delegate;
@property (nullable, nonatomic) FBSDKErrorRecoveryAttempter *recoveryAttempter;
@property (nullable, nonatomic) NSError *_error;

@end

@implementation FBSDKGraphErrorRecoveryProcessor

+ (instancetype)new
{
  return [[FBSDKGraphErrorRecoveryProcessor alloc] init];
}

- (instancetype)init
{
  return [self initWithAccessTokenString:FBSDKAccessToken.currentAccessToken.tokenString];
}

- (instancetype)initWithAccessTokenString:(NSString *)accessTokenString
{
  if ((self = [super init])) {
    _accessToken = accessTokenString;
  }

  return self;
}

- (BOOL)processError:(NSError *)error
             request:(id<FBSDKGraphRequest>)request
            delegate:(id<FBSDKGraphErrorRecoveryProcessorDelegate>)delegate
{
  if ([delegate respondsToSelector:@selector(processorWillProcessError:error:)]) {
    if (![delegate processorWillProcessError:self error:error]) {
      return NO;
    }
  }

  FBSDKGraphRequestError errorCategory;
  id rawErrorCategory = error.userInfo[FBSDKGraphRequestErrorKey];
  if (rawErrorCategory && [rawErrorCategory respondsToSelector:@selector(unsignedIntegerValue)]) {
    errorCategory = [rawErrorCategory unsignedIntegerValue];
  } else {
    return NO;
  }

  switch (errorCategory) {
    case FBSDKGraphRequestErrorTransient:
      [delegate processorDidAttemptRecovery:self didRecover:YES error:nil];
      return YES;
    case FBSDKGraphRequestErrorRecoverable:
      if (request.tokenString && [request.tokenString isEqualToString:self.accessToken]) {
        self.recoveryAttempter = error.recoveryAttempter;
        [self.recoveryAttempter attemptRecoveryFromError:error
                                             optionIndex:0
                                       completionHandler:^(BOOL didRecover) {
                                         [delegate processorDidAttemptRecovery:self didRecover:didRecover error:error];
                                         self->_delegate = nil;
                                       }];
        return YES;
      }
      break;
    case FBSDKGraphRequestErrorOther:
      return NO;
  }
  return NO;
}

@end

#endif
