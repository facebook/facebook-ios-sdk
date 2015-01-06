/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBTaskCompletionSource.h"

#import "FBTask.h"

@interface FBTaskCompletionSource ()
@property (nonatomic, retain, readwrite) FBTask *task;
@end

@interface FBTask (FBTaskCompletionSource)
- (void)setResult:(id<NSObject>)result;
- (void)setError:(NSError *)error;
- (void)setException:(NSException *)exception;
- (void)cancel;
- (BOOL)trySetResult:(id<NSObject>)result;
- (BOOL)trySetError:(NSError *)error;
- (BOOL)trySetException:(NSException *)exception;
- (BOOL)trySetCancelled;
@end

@implementation FBTaskCompletionSource

+ (FBTaskCompletionSource *)taskCompletionSource {
    return [[[FBTaskCompletionSource alloc] init] autorelease];
}

- (instancetype)init {
    if ((self = [super init])) {
        _task = [[FBTask alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_task release];

    [super dealloc];
}

- (void)setResult:(id<NSObject>)result {
    [self.task setResult:result];
}

- (void)setError:(NSError *)error {
    [self.task setError:error];
}

- (void)setException:(NSException *)exception {
    [self.task setException:exception];
}

- (void)cancel {
    [self.task cancel];
}

- (BOOL)trySetResult:(id<NSObject>)result {
    return [self.task trySetResult:result];
}

- (BOOL)trySetError:(NSError *)error {
    return [self.task trySetError:error];
}

- (BOOL)trySetException:(NSException *)exception {
    return [self.task trySetException:exception];
}

- (BOOL)trySetCancelled {
    return [self.task trySetCancelled];
}

@end
