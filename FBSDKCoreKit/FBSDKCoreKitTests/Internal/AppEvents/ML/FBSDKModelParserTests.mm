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

#import "FBSDKMOdelConstants.h"
#import "FBSDKModelParser.h"
using mat::MTensor;
using std::string;
using std::unordered_map;
using std::vector;

@interface FBSDKModelParserTests : XCTestCase
{
  NSMutableDictionary<NSString *, NSArray *> *_mockWeightsInfoDict;
}
@end

@implementation FBSDKModelParserTests

- (void)setUp {
  _mockWeightsInfoDict = [[NSMutableDictionary alloc] init];
}

- (void)tearDown {
  [_mockWeightsInfoDict removeAllObjects];
}

- (void)testValidWeightsForAddressDetect {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [_mockWeightsInfoDict addEntriesFromDictionary:AddressDetectSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                forTask:FBSDKMTMLTaskAddressDetect];

  XCTAssertTrue(validatedRes);
}

- (void)testWeightsForAddressDetectWithMissingInfo {
  [_mockWeightsInfoDict addEntriesFromDictionary:AddressDetectSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                forTask:FBSDKMTMLTaskAddressDetect];

  XCTAssertFalse(validatedRes);
}

- (void)testWeightsForAddressDetectWithWrongInfo {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [_mockWeightsInfoDict addEntriesFromDictionary:AppEventPredSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                forTask:FBSDKMTMLTaskAddressDetect];

  XCTAssertFalse(validatedRes);
}

- (void)testValidWeightsForAppEventPred {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [_mockWeightsInfoDict addEntriesFromDictionary:AppEventPredSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                forTask:FBSDKMTMLTaskAppEventPred];

  XCTAssertTrue(validatedRes);
}

- (void)testWeightsForAppEventPredWithMissingInfo {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                forTask:FBSDKMTMLTaskAppEventPred];

  XCTAssertFalse(validatedRes);
}

- (void)testWeightsForAppEventPredWithWrongInfo {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [_mockWeightsInfoDict addEntriesFromDictionary:MTMLSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                forTask:FBSDKMTMLTaskAppEventPred];

  XCTAssertFalse(validatedRes);
}

- (void)testValidMTMLWeights {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [_mockWeightsInfoDict addEntriesFromDictionary:MTMLSpec];

  bool validatedRes = [FBSDKModelParser validateMTMLWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]];
  XCTAssertTrue(validatedRes);
}

- (void)testMTMLWeightsWithMissingInfo {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [_mockWeightsInfoDict addEntriesFromDictionary:AppEventPredSpec];

  bool validatedRes = [FBSDKModelParser validateMTMLWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]];
  XCTAssertFalse(validatedRes);
}

- (void)testMTMLWeightsWithWrongInfo {
  [_mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];

  bool validatedRes = [FBSDKModelParser validateMTMLWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]];
  XCTAssertFalse(validatedRes);
}

- (unordered_map<string, MTensor>)_mockWeightsWithRefDict:(NSDictionary<NSString *, NSArray *> *)dict {
  unordered_map<string,  MTensor> weights;
  for (NSString* key in dict) {
    NSArray<NSNumber *> *values = dict[key];
    vector<int64_t> shape;
    for (NSNumber *val in values) {
      shape.push_back(val.intValue);
    }
    MTensor tensor = mat::mempty(shape);
    weights[string([key UTF8String])] = tensor;
  }

  return weights;
}

@end
