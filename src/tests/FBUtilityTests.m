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

#import "FBTests.h"
#import "FBUtility.h"
#import "FacebookSDK.h"

@interface FBUtilityTests : FBTests
@end

@implementation FBUtilityTests

- (void)testUrlBuilding
{
    NSString *url;
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/post"
                                     version:nil];
    assertThat(url, equalTo(@"pre.facebook.com/" FB_IOS_SDK_TARGET_PLATFORM_VERSION @"/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/post"
                                     version:@"v0.1"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v0.1/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v0.2/post"
                                     version:@"v0.1"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v0.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v0.2/post"
                                     version:nil];
    
    assertThat(url, equalTo(@"pre.facebook.com/v0.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v987654321.2/post"
                                     version:nil];
    
    assertThat(url, equalTo(@"pre.facebook.com/v987654321.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v.2/post"
                                     version:@"v99.99"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v99.99/v.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v2/post"
                                     version:@"v99.99"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v99.99/v2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v2/post"
                                     version:@"v99.99"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v99.99/v2/post"));

}

@end
