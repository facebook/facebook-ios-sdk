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

NS_ASSUME_NONNULL_BEGIN

static NSDictionary<NSString *, NSString *> *const KEYS_MAPPING = @{@"embedding.weight": @"embed.weight",
                                                                    @"dense1.weight": @"fc1.weight",
                                                                    @"dense2.weight": @"fc2.weight",
                                                                    @"dense3.weight": @"fc3.weight",
                                                                    @"dense1.bias": @"fc1.bias",
                                                                    @"dense2.bias": @"fc2.bias",
                                                                    @"dense3.bias": @"fc3.bias"};

static NSDictionary<NSString *, NSArray *> *const SharedWeightsInfo =
  @{@"embed.weight" : @[@(256), @(64)],
    @"convs.0.weight" : @[@(32), @(64), @(2)],
    @"convs.0.bias" : @[@(32)],
    @"convs.1.weight" : @[@(32), @(64), @(3)],
    @"convs.1.bias" : @[@(32)],
    @"convs.2.weight" : @[@(32), @(64), @(5)],
    @"convs.2.bias" : @[@(32)],
    @"fc1.weight": @[@(128), @(126)],
    @"fc1.bias": @[@(128)],
    @"fc2.weight": @[@(64), @(128)],
    @"fc2.bias": @[@(64)]};

static NSDictionary<NSString *, NSArray *> *const AddressDetectSpec =
   @{@"fc3.weight": @[@(2), @(64)],
     @"fc3.bias": @[@(2)]};

static NSDictionary<NSString *, NSArray *> *const AppEventPredSpec =
  @{@"fc3.weight": @[@(4), @(64)],
    @"fc3.bias": @[@(4)]};

static NSDictionary<NSString *, NSArray *> *const MTMLSpec =
  @{@"address_detect.weight": @[@(2), @(64)],
    @"address_detect.bias": @[@(2)],
    @"app_event_pred.weight": @[@(4), @(64)],
    @"app_event_pred.bias": @[@(4)]};

NS_ASSUME_NONNULL_END
