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

#import "FBAppLinkDataTests.h"
#import "FBAppLinkData+Internal.h"
#import "FBTests.h"

@implementation FBAppLinkDataTests

- (void)testParseTargetURL
{
    NSURL *testURL = [[NSURL alloc] initWithString:@"fb123://authorize#expires_in=0&access_token=12345&target_url=http://target-url.com/?deeplink=1&fb_action_types=action1,action2&fb_source=source&fb_ref=ref1,ref2"];
    NSArray *testActionType = [[NSArray alloc] initWithObjects:@"action1", @"action2", nil];
    NSDictionary *testOriginalQueryParameters = [[NSDictionary alloc] initWithObjectsAndKeys:@"0", @"expires_in",
                                                                                             @"12345", @"access_token",
                                                                                             @"http://target-url.com/?deeplink=1", @"target_url",
                                                                                             @"action1,action2", @"fb_action_types",
                                                                                             @"source", @"fb_source",
                                                                                             @"ref1,ref2", @"fb_ref",
                                                                                             nil];
        
    FBAppLinkData *contentLink = [FBAppLinkData createFromURL:testURL];
    
    STAssertNotNil(contentLink, @"Failed to create an FBAppLinkData object");
    STAssertEqualObjects([[NSURL alloc] initWithString:@"http://target-url.com/?deeplink=1"], contentLink.targetURL, @"Failed to correctly parse target_url");
    STAssertTrue([contentLink.actionTypes isEqualToArray:testActionType], @"Failed to correctly parse fb_action_types");
    STAssertTrue([contentLink.originalQueryParameters isEqualToDictionary:testOriginalQueryParameters], @"Incorrect originalQueryParameters");
}

@end
