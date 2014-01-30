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

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

@class FBTestBlocker;

typedef void (^FBTestBlockerPeriodicHandler)(FBTestBlocker *blocker);

// FBTestBlocker class
//
// Summary:
// Lightweight helper to make unit tests more linear and readable; currently supports blocks,
// can be extended to support delegates as needed
// NOTE: Not safe to call outside the context of unit tests, as [FBTestBlocker wait] runs
// the currentRunLoop, and framework code, etc., is not guaranteed to be re-entrant.
// SenTestKit does not run tests in the context of a run loop.
// Also, not thread-safe, expects all signaling to happen on the same thread.
@interface FBTestBlocker : NSObject

- (instancetype)initWithExpectedSignalCount:(NSInteger)expectedSignalCount;
- (void)wait;
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout;
- (void)waitWithPeriodicHandler:(FBTestBlockerPeriodicHandler)handler;
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout periodicHandler:(FBTestBlockerPeriodicHandler)handler;
- (void)signal;

+ (void)waitForVerifiedMock:(OCMockObject *)inMock delay:(NSTimeInterval)inDelay;

@end
