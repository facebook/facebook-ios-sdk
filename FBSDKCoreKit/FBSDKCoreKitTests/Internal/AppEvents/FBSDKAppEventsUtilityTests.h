/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@class TestAppEventsStateProvider;
@class TestBundle;
@class TestEventLogger;
@class UserDefaultsSpy;

// The interface for FBSDKAppEventsUtilityTests is not in the .m file since part of the tests are in a swift extension

@interface FBSDKAppEventsUtilityTests : XCTestCase

@property (nonatomic) UserDefaultsSpy *userDefaultsSpy;
@property (nonatomic) TestBundle *bundle;
@property (nonatomic) TestEventLogger *logger;
@property (nonatomic) TestAppEventsStateProvider *appEventsStateProvider;

@end

NS_ASSUME_NONNULL_END
