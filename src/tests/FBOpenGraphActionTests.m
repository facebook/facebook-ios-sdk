/*
 * Copyright 2012 Facebook
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

#if defined(FBIOSSDK_SKIP_OPEN_GRAPH_ACTION_TESTS) || !defined(UNIT_TEST_OPEN_GRAPH_NAMESPACE)

#pragma message ("warning: Skipping FBOpenGraphActionTests")

#else

@interface FBOpenGraphActionTests ()

@end

@implementation FBOpenGraphActionTests

- (id<FBOGTestObject>)openGraphTestObject:(NSString*)testName
{
    // This URL is specific to this test, and can be used to create arbitrary
    // OG objects for this app; your OG objects will have URLs hosted by your server.
    NSString *format =  
        @"http://fbsdkog.herokuapp.com/repeater.php?"
        @"fb:app_id=171298632997486&og:type=%@&"
        @"og:title=%@&og:description=%%22%@%%22&"
        @"og:image=https://s-static.ak.fbcdn.net/images/devsite/attachment_blank.png&"
        @"body=%@";
    
    // We create an FBGraphObject object, but we can treat it as an SCOGMeal with typed
    // properties, etc. See <FBiOSSDK/FBGraphObject.h> for more details.
    id<FBOGTestObject> result = (id<FBOGTestObject>)[FBGraphObject graphObject];
    
    // Give it a URL that will echo back the name of the meal as its title, description, and body.
    result.url = [NSString stringWithFormat:format, @UNIT_TEST_OPEN_GRAPH_NAMESPACE":test", testName, testName, testName];
    
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

- (id<FBOGRunTestAction>)createComplexOpenGraphAction:(NSString*)taggedUserID {
    id<FBOGTestObject> testObject = [self openGraphTestObject:@"testPostingComplexOpenGraphAction"];
    
    id<FBGraphPlace> placeObject = (id<FBGraphPlace>)[FBGraphObject graphObject];
    placeObject.id = @"154981434517851";
    
    id<FBGraphUser> userObject = (id<FBGraphUser>)[FBGraphObject graphObject];
    userObject.id = taggedUserID;
    
    id<FBOGRunTestAction> action = (id<FBOGRunTestAction>)[FBGraphObject graphObject];
    action.test = testObject;
    action.place = placeObject;
    action.tags = [NSArray arrayWithObject:userObject];
    
    NSMutableDictionary *image = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"true", @"user_generated", 
                                  @"http://fbsdkog.herokuapp.com/1.jpg", @"url",
                                  nil];
    NSMutableArray *images = [NSArray arrayWithObject:image];
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
                                      @"place",
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
                               @"place",
                               @"tags",
                               nil]];
}

@end

#endif
