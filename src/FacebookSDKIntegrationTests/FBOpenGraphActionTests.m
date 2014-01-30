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

#import "FBOpenGraphActionTests.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBGraphPlace.h"
#import "FBGraphUser.h"
#import "FBTestSession.h"

#if defined(FACEBOOKSDK_SKIP_OPEN_GRAPH_ACTION_TESTS) || !defined(UNIT_TEST_OPEN_GRAPH_NAMESPACE)

#pragma message ("warning: Skipping FBOpenGraphActionTests")

#else

@interface FBOpenGraphActionTests ()

@end

@implementation FBOpenGraphActionTests

- (id<FBOGTestObject>)openGraphTestObject:(NSString *)testName {
    // We create an FBGraphObject object, but we can treat it as an SCOGMeal with typed
    // properties, etc. See <FacebookSDK/FBGraphObject.h> for more details.
    id<FBOGTestObject> result = (id<FBOGTestObject>)[FBGraphObject graphObject];

    // Give it a URL of sample data that contains the object's name, title, description, and body.
    if ([testName isEqualToString:@"testPostingSimpleOpenGraphAction"]) {
        result.url = @"http://samples.ogp.me/414237771945858";
    } else if ([testName isEqualToString:@"testPostingComplexOpenGraphAction"]) {
        result.url = @"http://samples.ogp.me/414238245279144";
    }
    return result;
}

- (void)testPostingSimpleOpenGraphAction {
    id<FBOGTestObject> testObject = [self openGraphTestObject:@"testPostingSimpleOpenGraphAction"];

    id<FBOGRunTestAction> action = (id<FBOGRunTestAction>)[FBGraphObject graphObject];
    action.test = testObject;

    [self postAndValidateWithSession:self.defaultTestSession
                           graphPath:@"me/"UNIT_TEST_OPEN_GRAPH_NAMESPACE":run"
                         graphObject:action
                       hasProperties:[NSArray arrayWithObjects:
                                      nil]];

}

- (id<FBOGRunTestAction>)createComplexOpenGraphAction:(NSString *)taggedUserID {
    id<FBOGTestObject> testObject = [self openGraphTestObject:@"testPostingComplexOpenGraphAction"];

    id<FBGraphUser> userObject = (id<FBGraphUser>)[FBGraphObject graphObject];
    userObject.id = taggedUserID;

    id<FBOGRunTestAction> action = (id<FBOGRunTestAction>)[FBGraphObject graphObject];
    action.test = testObject;
    action.tags = [NSArray arrayWithObject:userObject];

    NSDictionary *image = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"https://sphotos-b.xx.fbcdn.net/hphotos-ash4/387972_10152013102225492_1756755651_n.jpg", @"url",
                           nil];
    NSArray *images = [NSArray arrayWithObject:image];
    action.image = images;

    return action;
}

- (void)testPostingComplexOpenGraphAction {
    FBTestSession *session1 = self.defaultTestSession;
    FBTestSession *session2 = [self getSessionWithSharedUserWithPermissions:nil
                                                              uniqueUserTag:kSecondTestUserTag];
    [self makeTestUserInSession:session1 friendsWithTestUserInSession:session2];

    id<FBOGRunTestAction> action = [self createComplexOpenGraphAction:session2.testUserID];

    [self postAndValidateWithSession:session1
                           graphPath:@"me/"UNIT_TEST_OPEN_GRAPH_NAMESPACE":run"
                         graphObject:action
                       hasProperties:[NSArray arrayWithObjects:
                                      @"image",
                                      @"tags",
                                      nil]];
}

- (void)testPostingComplexOpenGraphActionInBatch {
    FBTestSession *session1 = self.defaultTestSession;
    FBTestSession *session2 = [self getSessionWithSharedUserWithPermissions:nil
                                                              uniqueUserTag:kSecondTestUserTag];
    [self makeTestUserInSession:session1 friendsWithTestUserInSession:session2];

    id<FBOGRunTestAction> action = [self createComplexOpenGraphAction:session2.testUserID];

    id postedAction = [self batchedPostAndGetWithSession:session1 graphPath:@"me/"UNIT_TEST_OPEN_GRAPH_NAMESPACE":run" graphObject:action];
    STAssertNotNil(postedAction, @"nil postedAction");

    [self validateGraphObject:postedAction
                hasProperties:[NSArray arrayWithObjects:
                               @"image",
                               @"tags",
                               nil]];
}

- (void)testPostingUserGeneratedImageInAction
{
    id<FBOGTestObject> testObject = [self openGraphTestObject:@"testPostingSimpleOpenGraphAction"];

    id<FBOGRunTestAction> action = (id<FBOGRunTestAction>)[FBGraphObject graphObject];
    action.test = testObject;

    // Note: we pass user_generated=false rather than true because apps must be approved for
    // user-generated photos and that's extra work for the unit-test-app creator. false achieves
    // the same goal (just checking that it was round-tripped).
    NSDictionary *image = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"false", @"user_generated",
                           @"https://sphotos-b.xx.fbcdn.net/hphotos-ash4/387972_10152013102225492_1756755651_n.jpg", @"url",
                           nil];
    NSArray *images = [NSArray arrayWithObject:image];
    action.image = images;

    id postedAction = [self batchedPostAndGetWithSession:self.defaultTestSession
                                               graphPath:@"me/"UNIT_TEST_OPEN_GRAPH_NAMESPACE":run"
                                             graphObject:action];
    STAssertNotNil(postedAction, @"nil postedAction");

    NSArray *postedImages = [postedAction objectForKey:@"image"];
    STAssertNotNil(postedImages, @"nil images");
    STAssertTrue(1 == postedImages.count, @"not 1 image");

    id<FBGraphObject> postedImage = [postedImages objectAtIndex:0];
    [self validateGraphObject:postedImage hasProperties:[NSArray arrayWithObjects:
                                                         @"url",
                                                         @"user_generated",
                                                         nil]];
}

@end

#endif
