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

#import "FBDialogsParams+Internal.h"
#import "FBOpenGraphActionParams.h"
#import "FBTests.h"

@interface FBOpenGraphActionParamsTests : FBTests
@end

@implementation FBOpenGraphActionParamsTests

- (void)testAllowsInlineOG
{
    id action = [FBGraphObject openGraphActionForPost];
    id book = [FBGraphObject openGraphObjectForPostWithType:@"books.book"
                                                      title:@"Narrative of the Life of Frederick Douglass, an American Slave"
                                                      image:nil
                                                        url:nil
                                                description:@"Worthy of a read."];
    action[@"book"] = book;
    FBOpenGraphActionParams *params = [[[FBOpenGraphActionParams alloc] initWithAction:action
                                                                           actionType:@"books.reads"
                                                                  previewPropertyName:@"book"] autorelease];

    assertThat([params validate], is(nilValue()));
}

- (void)testAllowsOGUrl
{
    id action = [FBGraphObject openGraphActionForPost];
    action[@"book"] = @"http://en.wikipedia.org/wiki/Narrative_of_the_Life_of_Frederick_Douglass,_an_American_Slave";
    FBOpenGraphActionParams *params = [[[FBOpenGraphActionParams alloc] initWithAction:action
                                                                            actionType:@"books.reads"
                                                                   previewPropertyName:@"book"] autorelease];

    assertThat([params validate], is(nilValue()));
}

- (void)testDisallowsEmpty
{
    FBOpenGraphActionParams *params = [[FBOpenGraphActionParams alloc] init];

    assertThat([params validate], isNot(nilValue()));
}

- (void)testDisallowsWrongPreview
{
    id action = [FBGraphObject openGraphActionForPost];
    action[@"book"] = @"http://en.wikipedia.org/wiki/Narrative_of_the_Life_of_Frederick_Douglass,_an_American_Slave";
    FBOpenGraphActionParams *params = [[FBOpenGraphActionParams alloc] initWithAction:action actionType:@"books.reads" previewPropertyName:@"wrong"];

    assertThat([params validate], isNot(nilValue()));
}

- (void)testDisallowsWrongBadOG
{
    id action = [FBGraphObject openGraphActionForPost];
    action[@"book"] = @{ @"title":@"somebook"};

    FBOpenGraphActionParams *params = [[FBOpenGraphActionParams alloc] initWithAction:action actionType:@"books.reads" previewPropertyName:@"book"];

    assertThat([params validate], isNot(nilValue()));
}

@end
