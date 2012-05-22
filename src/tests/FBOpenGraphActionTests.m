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
#import "FBSession.h"

#if defined(FBIOSSDK_SKIP_OPEN_GRAPH_ACTION_TESTS)

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
    result.url = [NSString stringWithFormat:format, @"fbiossdktests:test", testName, testName, testName];
    
    return result;
}

- (void)testPostingSimpleOpenGraphAction {
    FBSession *session = [self loginTestUserWithPermissions:nil];
    id<FBOGTestObject> testObject = [self openGraphTestObject:@"testPostingSimpleOpenGraphAction"];
    
    id<FBOGRunTestAction> action = (id<FBOGRunTestAction>)[FBGraphObject graphObject];
    action.test = testObject;
    
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBRequest startForPostWithSession:session
                             graphPath:@"me/fbiossdktests:run"
                           graphObject:action
                     completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         STAssertTrue(!error, @"!error");
         if (!error) {
         } 
         [blocker signal];
     }];
    [blocker wait];
}

- (void)validateGraphObjectWithId:(NSString*)idString hasProperties:(NSArray*)propertyNames withSession:(FBSession*)session {
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBRequest startWithSession:session
                      graphPath:idString
              completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         STAssertTrue(!error, @"!error");
         STAssertTrue([idString isEqualToString:[result objectForKey:@"id"]], @"wrong id");
         for (NSString *propertyName in propertyNames) {
             STAssertNotNil([result objectForKey:propertyName], 
                            [NSString stringWithFormat:@"missing property '%@'", propertyName]);
         }
         [blocker signal];
     }];
    [blocker wait];
}

- (void)postAndValidateWithSession:(FBSession*)session graphPath:(NSString*)graphPath graphObject:(id)graphObject hasProperties:(NSArray*)propertyNames {
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBRequest startForPostWithSession:session
                                                              graphPath:graphPath
                                                            graphObject:graphObject
                                                      completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            STAssertTrue(!error, @"!error");
            if (!error) {
                NSString *newObjectId = [result objectForKey:@"id"];
                    [self validateGraphObjectWithId:newObjectId
                                      hasProperties:propertyNames
                                        withSession:session];
            } 
            [blocker signal];
        }];
    [blocker wait];    
}

- (void)testPostingComplexOpenGraphAction {
    FBSession *session1 = [self loginTestUserWithPermissions:nil];
    FBSession *session2 = [self loginTestUserWithPermissions:nil];
    [self makeTestUserInSession:session1 friendsWithTestUserInSession:session2];
    
    id<FBOGTestObject> testObject = [self openGraphTestObject:@"testPostingSimpleOpenGraphAction"];
    
    id<FBGraphPlace> placeObject = (id<FBGraphPlace>)[FBGraphObject graphObject];
    placeObject.id = @"154981434517851";

    id<FBGraphUser> userObject = (id<FBGraphUser>)[FBGraphObject graphObject];
    userObject.id = [FBSession testUserIDForSession:session2];
    
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
    
    [self postAndValidateWithSession:session1 
                           graphPath:@"me/fbiossdktests:run" 
                         graphObject:action 
                       hasProperties:[NSArray arrayWithObjects:
                                      @"image", 
                                      @"place",
                                      @"tags",
                                      nil]];
}

@end

#endif
