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

#import "FBIntegrationTests.h"
#import "FBOpenGraphAction.h"

@protocol FBOGTestObject<FBGraphObject>

@property (retain, nonatomic) NSString        *title;
@property (retain, nonatomic) NSString        *url;

@end

@protocol FBOGRunTestAction<FBOpenGraphAction>

@property (retain, nonatomic) id<FBOGTestObject>    test;

@end

@interface FBOpenGraphActionTests : FBIntegrationTests

@end

// Open Graph namespaces must be unique, so running these tests against specific
// Facebook Applications will require choosing a new namespace.
#define UNIT_TEST_OPEN_GRAPH_NAMESPACE "facebooksdktests"
