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

#import "FBSessionTests.h"
#import "FBSession.h"
#import "FBRequest.h"
#import "FBGraphUser.h"
#import "FBTestBlocker.h"

@implementation FBSessionTests

// All code under test must be linked into the Unit Test bundle
- (void)testSessionBasic
{
    // create valid
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    
    FBSession *session = [FBSession sessionForUnitTestingWithPermissions:nil];
    [session loginWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        [blocker signal];
    }];
    
    [blocker wait];
    
    STAssertTrue(session.isValid, @"Session should be valid, and is not");
    
    [[FBRequest connectionWithSession:session
                            graphPath:@"me" 
                    completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> me, NSError *error) {
                         STAssertTrue(me.id.length > 0, @"user id should be non-empty");
                         [blocker signal];
                     }] 
     start];
    
    [blocker wait];
    
    [session invalidate];
}

// All code under test must be linked into the Unit Test bundle
- (void)testSessionInvalidate
{
    // create valid
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    
    __block BOOL wasNotifiedOfInvalid = NO;
    
    FBSession *session = [FBSession sessionForUnitTestingWithPermissions:nil];
    [session loginWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        if (status == FBSessionStateInvalidated) {
            wasNotifiedOfInvalid = YES;
        }
        [blocker signal];
    }];
    
    [blocker wait];
    
    STAssertTrue(session.isValid, @"Session should be valid, and is not");
    
    __block NSString *userID;
    [[FBRequest connectionWithSession:session
                            graphPath:@"me" 
                    completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> me, NSError *error) {
                        userID = [me.id retain];
                        STAssertTrue(userID.length > 0, @"user id should be non-empty");
                        [blocker signal];
                    }] 
     start];
    
    [blocker wait];
    
    // use FBRequest to create an NSURLRequest
    NSURLRequest *request = [FBRequest connectionWithSession:session
                                                   graphPath:userID
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"delete", @"method",
                                                              nil]
                                                  HTTPMethod:nil
                                           completionHandler:nil].urlRequest;
    
    [userID release];
    
    // synchronously delete the user
    NSURLResponse *response;
    NSError *error = nil;
    NSData *data;
    data = [NSURLConnection sendSynchronousRequest:request 
                                 returningResponse:&response
                                             error:&error];
    // if !data or if data == false, log
    NSString *body = !data ? nil : [[[NSString alloc] initWithData:data
                                                          encoding:NSUTF8StringEncoding]
                                    autorelease];    
    STAssertTrue([body isEqualToString:@"true"], @"body should return 'true'");
        
    [[FBRequest connectionWithSession:session
                            graphPath:@"me" 
                    completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> me, NSError *error) {
                        STAssertTrue(error != nil, @"response should be an error due to deleted user");
                        [blocker signal];
                    }] 
     start];

    STAssertFalse(wasNotifiedOfInvalid, @"should not have invalidated the token yet");
    [blocker wait];
    STAssertTrue(wasNotifiedOfInvalid, @"should have invalidated the token by now");
    
    [session invalidate];
}

@end
