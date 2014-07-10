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
#import "FBShareDialogPhotoParams.h"
#import "FBTests.h"

@interface FBPhotoParamsTests : FBTests
@end

@implementation FBPhotoParamsTests

- (void)testAllowsSinglePhoto
{
    NSArray *photos = @[
                        [[[UIImage alloc] init] autorelease],
                        ];
    FBPhotoParams *params = [[[FBPhotoParams alloc] initWithPhotos:photos] autorelease];
    XCTAssertNil([params validate]);
}

- (void)testAllowsMultiplePhotos
{
    NSArray *photos = @[
                        [[[UIImage alloc] init] autorelease],
                        [[[UIImage alloc] init] autorelease],
                        [[[UIImage alloc] init] autorelease],
                        ];
    FBPhotoParams *params = [[[FBPhotoParams alloc] initWithPhotos:photos] autorelease];
    XCTAssertNil([params validate]);
}

- (void)testRequiresPhotos
{
    FBPhotoParams *params = [[[FBPhotoParams alloc] init] autorelease];
    XCTAssertNotNil([params validate]);
}

- (void)testCopy
{
    NSArray *photos = @[
                        [[[UIImage alloc] init] autorelease],
                        [[[UIImage alloc] init] autorelease],
                        [[[UIImage alloc] init] autorelease],
                        ];
    FBPhotoParams *params = [[[FBPhotoParams alloc] initWithPhotos:photos] autorelease];

    FBPhotoParams *paramsCopy = [[params copy] autorelease];
    XCTAssertEqualObjects(params.photos, photos);
    XCTAssertEqualObjects(paramsCopy.photos, photos);

    paramsCopy.photos = [paramsCopy.photos subarrayWithRange:NSMakeRange(0, 2)];
    XCTAssertEqualObjects(params.photos, photos);
    XCTAssertNotEqualObjects(paramsCopy.photos, photos);
}

@end
