/*
 * Copyright 2013 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import <Foundation/Foundation.h>

@class FBTask;

/*!
 A FBTaskCompletionSource represents the producer side of tasks.
 It is a task that also has methods for changing the state of the
 task by settings its completion values.
 */
@interface FBTaskCompletionSource : NSObject

/*!
 Creates a new unfinished task.
 */
+ (FBTaskCompletionSource *)taskCompletionSource;

/*!
 The task associated with this TaskCompletionSource.
 */
@property (nonatomic, retain, readonly) FBTask *task;

/*!
 Completes the task by setting the result.
 Attempting to set this for a completed task will raise an exception.
 */
- (void)setResult:(id)result;

/*!
 Completes the task by setting the error.
 Attempting to set this for a completed task will raise an exception.
 */
- (void)setError:(NSError *)error;

/*!
 Completes the task by setting an exception.
 Attempting to set this for a completed task will raise an exception.
 */
- (void)setException:(NSException *)exception;

/*!
 Completes the task by marking it as cancelled.
 Attempting to set this for a completed task will raise an exception.
 */
- (void)cancel;

/*!
 Sets the result of the task if it wasn't already completed.
 @returns whether the new value was set.
 */
- (BOOL)trySetResult:(id)result;

/*!
 Sets the error of the task if it wasn't already completed.
 @returns whether the new value was set.
 */
- (BOOL)trySetError:(NSError *)error;

/*!
 Sets the exception of the task if it wasn't already completed.
 @returns whether the new value was set.
 */
- (BOOL)trySetException:(NSException *)exception;

/*!
 Sets the cancellation state of the task if it wasn't already completed.
 @returns whether the new value was set.
 */
- (BOOL)trySetCancelled;

@end
