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

#import "FBSDKTestBlocker.h"

#import <XCTest/XCTest.h>

@implementation FBSDKTestBlocker
{
    NSInteger _signalsRemaining;
    NSInteger _expectedSignalCount;
}

- (instancetype)init {
    return [self initWithExpectedSignalCount:1];
}

- (instancetype)initWithExpectedSignalCount:(NSInteger)expectedSignalCount {
    if ((self = [super init])) {
        _expectedSignalCount = expectedSignalCount;
        [self reset];
    }
    return self;
}

- (void)wait {
    [self waitWithTimeout:0];
}

- (void)waitWithPeriodicHandler:(FBSDKTestBlockerPeriodicHandler)handler {
    [self waitWithTimeout:0
          periodicHandler:handler];
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout {
    return [self waitWithTimeout:timeout
                 periodicHandler:nil];
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout
        periodicHandler:(FBSDKTestBlockerPeriodicHandler)handler {
    NSDate *start = [NSDate date];

    // loop until the previous call completes
    while (_signalsRemaining > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
        if (timeout > 0 &&
            [[NSDate date] timeIntervalSinceDate:start] > timeout) {
            [self reset];
            return NO;
        }
        if (handler) {
            handler(self);
        }
    };
    [self reset];
    return YES;
}

- (void)signal {
    --_signalsRemaining;
}

- (void)reset {
    _signalsRemaining = _expectedSignalCount;
}

+ (void)waitForVerifiedMock:(OCMockObject *)inMock delay:(NSTimeInterval)inDelay
{
    NSTimeInterval i = 0;
    while (i < inDelay)
    {
        @try
        {
            [inMock verify];
            return;
        }
        @catch (NSException *e) {}
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        i+=0.5;
    }
    [inMock verify];
}

@end


// this is unrelated to test-blocker, but is a useful hack to make it easy to retarget the url
// without checking certs
@interface NSURLRequest (NSURLRequestWithIgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host;
@end

@implementation NSURLRequest (NSURLRequestWithIgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    return YES;
}
@end
