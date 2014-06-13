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

#import <Bolts/Bolts.h>

#import "FBAppLinkResolver.h"
#import "FBIntegrationTests.h"
#import "FBInternalSettings.h"
#import "FBTestSession+Internal.h"

static NSString *const kAppLinkURLString = @"https://www.facebook.com/l.php?u=https%3A%2F%2Ffb.me%2F732873156764191&h=bAQE7eGV2";

@interface FBAppLinksIntegrationTests : FBIntegrationTests

@end

@implementation FBAppLinksIntegrationTests

- (void)setUp
{
    [super setUp];

    FBTestSession *session = [FBTestSession sessionWithSharedUserWithPermissions:nil];

    [FBSettings setDefaultAppID:session.testAppID];
    [FBSettings setClientToken:session.testAppClientToken];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)waitForTaskOnMainThread:(BFTask *)task
{
    while (!task.isCompleted) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)testResolveWorks
{
    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    BFAppLink *link = task.result;
    assertThat(link, is(notNilValue()));
    assertThat(link.webURL.absoluteString, is(equalTo(kAppLinkURLString)));
}

 - (void)testErrorWithoutClientToken
{
    [FBSettings setClientToken:nil];

    FBAppLinkResolver *resolver = [FBAppLinkResolver resolver];

    BFTask *task = [resolver appLinkFromURLInBackground:[NSURL URLWithString:kAppLinkURLString]];
    [self waitForTaskOnMainThread:task];

    assertThat(task.error, is(notNilValue()));

    // restore the client token for later tests.
    FBTestSession *session = [FBTestSession sessionWithSharedUserWithPermissions:nil];
    [FBSettings setDefaultAppID:session.testAppID];
    [FBSettings setClientToken:session.testAppClientToken];
}
@end
