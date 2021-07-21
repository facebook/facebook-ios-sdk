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
 #import "FBSDKAEMNetworker.h"

 #import <Foundation/Foundation.h>

 #import "FBSDKGraphRequest+Internal.h"
 #import "FBSDKGraphRequestFlags.h"

@implementation FBSDKAEMNetworker

- (void)startGraphRequestWithGraphPath:(NSString *)graphPath
                            parameters:(NSDictionary *)parameters
                           tokenString:(nullable NSString *)tokenString
                            HTTPMethod:(nullable NSString *)method
                            completion:(FBGraphRequestCompletion)completion
{
  id<FBSDKGraphRequest> graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                                                         parameters:parameters
                                                                        tokenString:tokenString
                                                                         HTTPMethod:method
                                                                              flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery];

  [graphRequest startWithCompletion:^(id<FBSDKGraphRequestConnecting> _Nullable connection, id _Nullable result, NSError *_Nullable error) {
    completion(result, error);
  }];
}

@end

#endif
