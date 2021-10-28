/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorRecoveryAttempter.h"

#import "FBSDKErrorRecoveryConfiguration.h"

@interface FBSDKTemporaryErrorRecoveryAttempter : FBSDKErrorRecoveryAttempter
@end

@implementation FBSDKTemporaryErrorRecoveryAttempter

- (void)attemptRecoveryFromError:(NSError *)error completionHandler:(void (^)(BOOL didRecover))completionHandler
{
  @try {
    completionHandler(YES);
  } @catch (NSException *exception) {
    NSLog(@"Fail to complete error recovery. Exception reason: %@", exception.reason);
  }
}

@end

@implementation FBSDKErrorRecoveryAttempter

+ (nullable instancetype)recoveryAttempterFromConfiguration:(FBSDKErrorRecoveryConfiguration *)configuration
{
  if (configuration.errorCategory == FBSDKGraphRequestErrorTransient) {
    return [FBSDKTemporaryErrorRecoveryAttempter new];
  } else if (configuration.errorCategory == FBSDKGraphRequestErrorOther) {
    return nil;
  }
  if ([configuration.recoveryActionName isEqualToString:@"login"]) {
    Class loginRecoveryAttmpterClass = NSClassFromString(@"FBSDKLoginRecoveryAttempter");
    if (loginRecoveryAttmpterClass) {
      return [loginRecoveryAttmpterClass new];
    }
  }
  return nil;
}

- (void)attemptRecoveryFromError:(NSError *)error completionHandler:(void (^)(BOOL didRecover))completionHandler
{
  // should be implemented by subclasses.
}

@end
