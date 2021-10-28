/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 a formal protocol very similar to the informal protocol NSErrorRecoveryAttempting
 */
NS_SWIFT_NAME(ErrorRecoveryAttempting)
@protocol FBSDKErrorRecoveryAttempting <NSObject>

/**
 attempt the recovery
 @param error the error
 @param recoveryOptionIndex the selected option index
 @param completionHandler the handler called upon completion of error recovery

 Given that an error alert has been presented document-modally to the user, and the user has chosen one of the error's recovery options, attempt recovery from the error, and call the completion handler. The option index is an index into the error's array of localized recovery options. The value passed for didRecover must be YES if error recovery was completely successful, NO otherwise.
 */
- (void)attemptRecoveryFromError:(NSError *)error
                     optionIndex:(NSUInteger)recoveryOptionIndex
               completionHandler:(void (^)(BOOL didRecover))completionHandler;
@end

NS_ASSUME_NONNULL_END
