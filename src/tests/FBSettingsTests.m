/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBInternalSettings.h"
#import "FBTests.h"

@interface FBSettingsTests : FBTests
@end

@implementation FBSettingsTests

- (void)testBetaMode
{
    XCTAssertFalse([FBSettings isBetaFeatureEnabled:FBBetaFeaturesShareDialog], @"share dialog not enabled");
    [FBSettings enableBetaFeature:FBBetaFeaturesOpenGraphShareDialog];
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:FBBetaFeaturesOpenGraphShareDialog], @"OG share dialog enabled");
    [FBSettings disableBetaFeature:FBBetaFeaturesOpenGraphShareDialog];
    XCTAssertFalse([FBSettings isBetaFeatureEnabled:FBBetaFeaturesOpenGraphShareDialog], @"OG share dialog disabled");
    [FBSettings enableBetaFeatures:FBBetaFeaturesShareDialog | FBBetaFeaturesOpenGraphShareDialog];
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:FBBetaFeaturesOpenGraphShareDialog], @"OG share dialog enabled");
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:FBBetaFeaturesShareDialog], @"share dialog enabled");
    [FBSettings disableBetaFeature:FBBetaFeaturesShareDialog];
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:FBBetaFeaturesOpenGraphShareDialog], @"OG share dialog enabled");
    XCTAssertFalse([FBSettings isBetaFeatureEnabled:FBBetaFeaturesShareDialog], @"share dialog enabled");
    [FBSettings disableBetaFeature:FBBetaFeaturesOpenGraphShareDialog];
    XCTAssertFalse([FBSettings isBetaFeatureEnabled:FBBetaFeaturesOpenGraphShareDialog], @"OG share dialog disabled");
    XCTAssertFalse([FBSettings isBetaFeatureEnabled:FBBetaFeaturesShareDialog], @"share dialog enabled");
}

@end
