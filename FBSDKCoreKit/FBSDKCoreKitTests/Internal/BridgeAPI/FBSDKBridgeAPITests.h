/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKBridgeAPI+Testing.h"
#import "FBSDKCoreKitTests-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPITests : XCTestCase

@property (nonatomic) FBSDKBridgeAPI *api;
@property (nonatomic) TestLogger *logger;
@property (readonly) NSURL *sampleUrl;
@property (readonly) NSError *sampleError;
@property (nonatomic) TestInternalURLOpener *urlOpener;
@property (nonatomic) TestBridgeAPIResponseFactory *bridgeAPIResponseFactory;
@property (nonatomic) TestDylibResolver *frameworkLoader;
@property (nonatomic) TestInternalUtility *appURLSchemeProvider;
@property (nonatomic) TestErrorFactory *errorFactory;

extern NSString *const sampleSource;
extern NSString *const sampleAnnotation;

@end

NS_ASSUME_NONNULL_END
