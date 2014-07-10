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
#import "FBLinkShareParams.h"
#import "FBTests.h"

@interface FBLinkShareParamsTests : FBTests
@end

@implementation FBLinkShareParamsTests

- (void)testAllowsLink
{
    FBLinkShareParams *params = [[[FBLinkShareParams alloc] init] autorelease];
    params.link = [NSURL URLWithString:@"http://www.facebook.com"];
    XCTAssertNil([params validate]);
}

- (void)testDisallowsInvalidLinkSchema
{
    FBLinkShareParams *params = [[[FBLinkShareParams alloc] init] autorelease];
    params.link = [NSURL URLWithString:@"x-scheme://www.facebook.com"];
    XCTAssertNil(params.link);
}

- (void)testDisallowsInvalidLinkPictureSchema
{
    FBLinkShareParams *params = [[[FBLinkShareParams alloc] init] autorelease];
    params.picture = [NSURL URLWithString:@"x-scheme://www.facebook.com"];
    XCTAssertNil(params.picture);
}

- (void)testCopy
{
    NSURL *link = [NSURL URLWithString:@"http://www.facebook.com"];
    FBLinkShareParams *params = [[[FBLinkShareParams alloc] init] autorelease];
    params.link = link;

    FBLinkShareParams *paramsCopy = [[params copy] autorelease];
    XCTAssertEqualObjects(params.link, link);
    XCTAssertEqualObjects(paramsCopy.link, link);

    paramsCopy.link = [NSURL URLWithString:@"http://developers.facebook.com"];
    XCTAssertEqualObjects(params.link, link);
    XCTAssertNotEqualObjects(paramsCopy.link, link);
}

@end
