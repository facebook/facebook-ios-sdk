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

#import <Foundation/Foundation.h>

#import <OCMock/OCMock.h>

@class FBSDKTestBlocker;

typedef void (^FBSDKTestBlockerPeriodicHandler)(FBSDKTestBlocker *blocker);

// FBSDKTestBlocker class
//
// Summary:
// Lightweight helper to make unit tests more linear and readable; currently supports blocks,
// can be extended to support delegates as needed
// NOTE: Not safe to call outside the context of unit tests, as [FSDKBTestBlocker wait] runs
// the currentRunLoop, and framework code, etc., is not guaranteed to be re-entrant.
// XCTest does not run tests in the context of a run loop.
// Also, not thread-safe, expects all signaling to happen on the same thread.
@interface FBSDKTestBlocker : NSObject

- (instancetype)initWithExpectedSignalCount:(NSInteger)expectedSignalCount NS_DESIGNATED_INITIALIZER;
- (void)wait;
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout;
- (void)waitWithPeriodicHandler:(FBSDKTestBlockerPeriodicHandler)handler;
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout periodicHandler:(FBSDKTestBlockerPeriodicHandler)handler;
- (void)signal;

+ (void)waitForVerifiedMock:(OCMockObject *)inMock delay:(NSTimeInterval)inDelay;

@end
