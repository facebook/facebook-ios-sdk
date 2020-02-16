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
  NSMutableDictionary<NSString *, NSArray *> *mockWeightsInfoDict;
}
@end

@implementation FBSDKModelParserTests

- (void)setUp {
  mockWeightsInfoDict = [[NSMutableDictionary alloc] init];

}

- (void)tearDown {
  [mockWeightsInfoDict removeAllObjects];
}

- (void)testValidWeightsForAddressDetect {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [mockWeightsInfoDict addEntriesFromDictionary:AddressDetectSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]
                                                forTask:FBSDKOnDeviceMLTaskAddressDetect];

  XCTAssertTrue(validatedRes);
}

- (void)testWeightsForAddressDetectWithMissingInfo {
  [mockWeightsInfoDict addEntriesFromDictionary:AddressDetectSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]
                                                forTask:FBSDKOnDeviceMLTaskAddressDetect];

  XCTAssertFalse(validatedRes);
}

- (void)testWeightsForAddressDetectWithWrongInfo {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [mockWeightsInfoDict addEntriesFromDictionary:AppEventPredSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]
                                                forTask:FBSDKOnDeviceMLTaskAddressDetect];

  XCTAssertFalse(validatedRes);
}

- (void)testValidWeightsForAppEventPred {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [mockWeightsInfoDict addEntriesFromDictionary:AppEventPredSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]
                                                forTask:FBSDKOnDeviceMLTaskAppEventPred];

  XCTAssertTrue(validatedRes);
}

- (void)testWeightsForAppEventPredWithMissingInfo {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]
                                                forTask:FBSDKOnDeviceMLTaskAppEventPred];

  XCTAssertFalse(validatedRes);
}

- (void)testWeightsForAppEventPredWithWrongInfo {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [mockWeightsInfoDict addEntriesFromDictionary:MTMLSpec];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]
                                                forTask:FBSDKOnDeviceMLTaskAppEventPred];

  XCTAssertFalse(validatedRes);
}

- (void)testValidMTMLWeights {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [mockWeightsInfoDict addEntriesFromDictionary:MTMLSpec];

  bool validatedRes = [FBSDKModelParser validateMTMLWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]];
  XCTAssertTrue(validatedRes);
}

- (void)testMTMLWeightsWithMissingInfo {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [mockWeightsInfoDict addEntriesFromDictionary:AppEventPredSpec];

  bool validatedRes = [FBSDKModelParser validateMTMLWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]];
  XCTAssertFalse(validatedRes);
}

- (void)testMTMLWeightsWithWrongInfo {
  [mockWeightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];

  bool validatedRes = [FBSDKModelParser validateMTMLWeights:[self _mockWeightsWithRefDict:mockWeightsInfoDict]];
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
