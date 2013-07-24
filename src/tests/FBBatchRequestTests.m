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

#import "FBBatchRequestTests.h"
#import "FBTestSession.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBGraphUser.h"
#import "FBSettings.h"

@implementation FBBatchRequestTests

- (void)testBatchWithTwoSessionlessRequestsAndNoDefaultAppID
{
    [FBSettings setDefaultAppID:nil];

    FBRequest *request1 = [[[FBRequest alloc] initWithSession:nil
                                                    graphPath:@"zuck"]
                           autorelease];
    FBRequest *request2 = [[[FBRequest alloc] initWithSession:nil
                                                    graphPath:@"zuck"]
                           autorelease];
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    [connection addRequest:request1 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
         }];
    [connection addRequest:request2
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
         }];
    
    STAssertThrows([connection start], @"didn't throw");    
    [connection release];
}

@end
