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

typedef NS_ENUM(NSUInteger, FBSettingsTestsMockBetaFlags) {
    FBSettingsTestsMockBetaNone = 0,
    FBSettingsTestsMockBetaOne = 1 << 0,
    FBSettingsTestsMockBetaTwo = 1 << 1,
};

@implementation FBSettingsTests

- (void)testBetaMode
{
    [FBSettings enableBetaFeature:(FBBetaFeatures)FBSettingsTestsMockBetaOne];
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:(FBBetaFeatures)FBSettingsTestsMockBetaOne]);

    [FBSettings disableBetaFeature:(FBBetaFeatures)FBSettingsTestsMockBetaOne];
    XCTAssertFalse([FBSettings isBetaFeatureEnabled:(FBBetaFeatures)FBSettingsTestsMockBetaOne]);

    [FBSettings enableBetaFeatures:(FBBetaFeatures)(FBSettingsTestsMockBetaOne | FBSettingsTestsMockBetaTwo)];
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:(FBBetaFeatures)FBSettingsTestsMockBetaOne]);
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:(FBBetaFeatures)FBSettingsTestsMockBetaTwo]);

    [FBSettings disableBetaFeature:(FBBetaFeatures)FBSettingsTestsMockBetaTwo];
    XCTAssertTrue([FBSettings isBetaFeatureEnabled:(FBBetaFeatures)FBSettingsTestsMockBetaOne]);
    XCTAssertFalse([FBSettings isBetaFeatureEnabled:(FBBetaFeatures)FBSettingsTestsMockBetaTwo]);
}

@end
