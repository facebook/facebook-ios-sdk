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

#import <XCTest/XCTest.h>

#include "FBSDKModelRuntime.h"

@interface FBSDKModelRuntimeTests : XCTestCase

@end

@implementation FBSDKModelRuntimeTests

- (void)testMaxPool1DExample1 {
    int i,j;
    float* res;
    float input[2][2][3] = {
        {
            {-1, 2, 3},
            {4, -5, 6},
        },
        {
            {7, -8, 9},
            {-10, 11, 12},
        },
    };
    float expected[2][1][3] = {
        {{4, 2, 6}},
        {{7, 11, 12}},
    };
    res = mat1::maxPool1D(**input, 2, 2, 3, 2);
    for (i = 0; i < 2; i++) {
        for (j = 0; j < 3; j++) {
            XCTAssertEqualWithAccuracy(expected[i][0][j], res[3 * i + j], 0.01);
        }
    }
}

- (void)testMaxPool1DExample2 {
    int i,j;
    float* res;
    float input[2][2][3] = {
        {
            {-1, -2, -3},
            {-4, -5, -6},
        },
        {
            {-7, -8, -9},
            {-10, -11, -12},
        },
    };
    float expected[2][1][3] = {
        {{-1, -2, -3}},
        {{-7, -8, -9}},
    };
    res = mat1::maxPool1D(**input, 2, 2, 3, 2);
    for (i = 0; i < 2; i++) {
        for (j = 0; j < 3; j++) {
            XCTAssertEqualWithAccuracy(expected[i][0][j], res[3 * i + j], 0.01);
        }
    }
}

- (void)testMaxPool1DExample3 {
    int i,j;
    float* res;
    float input[3][3][4] = {
        {
            {-1, -2, -3, 3},
            {-4, -5, -6, 9},
            {4, 5, 6, 7},
        },
        {
            {-7, -8, -9, 9},
            {-10, -11, -12, 5},
            {4, 5, 6, 7},
        },
        {
            {-7, -8, -9, 0},
            {-10, -11, -12, 2},
            {4, 5, 6, 7},
        },
    };
    float expected[3][1][4] = {
        {{4, 5, 6, 9}},
        {{4, 5, 6, 9}},
        {{4, 5, 6, 7}},
    };
    res = mat1::maxPool1D(**input, 3, 3, 4, 3);
    for (i = 0; i < 3; i++) {
        for (j = 0; j < 4; j++) {
            XCTAssertEqualWithAccuracy(expected[i][0][j], res[4 * i + j], 0.01);
        }
    }
}

@end
