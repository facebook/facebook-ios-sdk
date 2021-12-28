/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import "FBSDKModelParser.h"
using fbsdk::MTensor;
using std::string;
using std::unordered_map;
using std::vector;

@interface FBSDKModelParser ()

+ (NSDictionary<NSString *, NSArray *> *)getMTMLWeightsInfo;

@end

@interface FBSDKModelParserTests : XCTestCase

@property (nonatomic) NSMutableDictionary<NSString *, NSArray *> *mockWeightsInfoDict;

@end

@implementation FBSDKModelParserTests

- (void)setUp
{
  _mockWeightsInfoDict = [NSMutableDictionary new];
}

- (void)tearDown
{
  [_mockWeightsInfoDict removeAllObjects];
}

- (void)testValidWeightsForMTML
{
  [_mockWeightsInfoDict addEntriesFromDictionary:[FBSDKModelParser getMTMLWeightsInfo]];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                 forKey:@"MTML"];

  XCTAssertTrue(validatedRes);
}

- (void)testWeightsForMissingInfo
{
  [_mockWeightsInfoDict removeAllObjects];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                 forKey:@"MTML"];

  XCTAssertFalse(validatedRes);
}

- (void)testWeightsForWrongInfo
{
  [_mockWeightsInfoDict addEntriesFromDictionary:[FBSDKModelParser getMTMLWeightsInfo]];
  [_mockWeightsInfoDict addEntriesFromDictionary:@{@"embed.weight" : @[@1, @1]}];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                 forKey:@"MTML"];

  XCTAssertFalse(validatedRes);
}

- (unordered_map<string, MTensor>)_mockWeightsWithRefDict:(NSDictionary<NSString *, NSArray *> *)dict
{
  unordered_map<string, MTensor> weights;
  for (NSString *key in dict) {
    NSArray<NSNumber *> *values = dict[key];
    vector<int> shape;
    for (NSNumber *val in values) {
      shape.push_back(val.intValue);
    }
    MTensor tensor(shape);
    weights[string([key UTF8String])] = tensor;
  }

  return weights;
}

@end
