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

#import "FBSDKModelParser.h"
using fbsdk::MTensor;
using std::string;
using std::unordered_map;
using std::vector;

@interface FBSDKModelParser ()

+ (NSDictionary<NSString *, NSArray *> *)getMTMLWeightsInfo;

@end

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

- (void)testValidWeightsForMTML {
  [_mockWeightsInfoDict addEntriesFromDictionary:[FBSDKModelParser getMTMLWeightsInfo]];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                 forKey:@"MTML"];

  XCTAssertTrue(validatedRes);
}

- (void)testWeightsForMissingInfo {
  [_mockWeightsInfoDict removeAllObjects];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                 forKey:@"MTML"];

  XCTAssertFalse(validatedRes);
}

- (void)testWeightsForWrongInfo {
  [_mockWeightsInfoDict addEntriesFromDictionary:[FBSDKModelParser getMTMLWeightsInfo]];
  [_mockWeightsInfoDict addEntriesFromDictionary:@{@"embed.weight" : @[@(1), @(1)]}];

  bool validatedRes = [FBSDKModelParser validateWeights:[self _mockWeightsWithRefDict:_mockWeightsInfoDict]
                                                 forKey:@"MTML"];

  XCTAssertFalse(validatedRes);
}

- (unordered_map<string, MTensor>)_mockWeightsWithRefDict:(NSDictionary<NSString *, NSArray *> *)dict {
  unordered_map<string,  MTensor> weights;
  for (NSString* key in dict) {
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
