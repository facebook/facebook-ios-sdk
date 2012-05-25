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

#import "FBTests.h"
#import "FBTestBlocker.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"

static NSMutableDictionary *mapTestCasesToSessions;
// Concurrency not an issue today, but guard our static global in any case.
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

#pragma mark Private interface

@interface FBTests ()

@end

#pragma mark -

@implementation FBTests

@synthesize defaultTestSession = _defaultTestSession;

#pragma mark Instance-level lifecycle

- (void)dealloc 
{   
    [_defaultTestSession release];
    [super dealloc];
}

- (void)setUp
{
    [super setUp];

    pthread_mutex_lock(&mutex);
    
    if (!mapTestCasesToSessions) {
        mapTestCasesToSessions = [[NSMutableDictionary alloc] init];
    }
    [mapTestCasesToSessions setObject:[[NSMutableArray alloc] init] 
                               forKey:[NSValue valueWithNonretainedObject:self]]; 
    
    pthread_mutex_unlock(&mutex);
}

- (void)tearDown
{
    pthread_mutex_lock(&mutex);
    
    NSMutableArray *sessions = [mapTestCasesToSessions objectForKey:[NSValue valueWithNonretainedObject:self]];
    [mapTestCasesToSessions removeObjectForKey:[NSValue valueWithNonretainedObject:self]];
    
    pthread_mutex_unlock(&mutex);
    
    for (FBSession *session in sessions) {
        [session close];
    }
    [sessions release];
    
    [super tearDown];
}

#pragma mark -
#pragma mark FBTestSession creation helpers

- (NSArray*)permissionsForDefaultTestSession
{
    return nil;
}

- (FBTestSession*)defaultTestSession
{
    if (!_defaultTestSession) {
        _defaultTestSession = [self getSessionWithSharedUserWithPermissions:[self permissionsForDefaultTestSession]];
    }
    return _defaultTestSession;
}

- (FBTestSession *)getSessionWithSharedUserWithPermissions:(NSArray*)permissions
{
    return [self getSessionWithSharedUserWithPermissions:permissions uniqueUserTag:nil];
}

- (FBTestSession *)getSessionWithSharedUserWithPermissions:(NSArray*)permissions 
                                             uniqueUserTag:(NSString*)uniqueUserTag
{
    FBTestSession *session = [FBTestSession sessionWithSharedUserWithPermissions:permissions uniqueUserTag:uniqueUserTag];
    
    // Need to remember all the sessions for this class.
    pthread_mutex_lock(&mutex);
    
    NSMutableArray *sessions = [mapTestCasesToSessions objectForKey:[NSValue valueWithNonretainedObject:self]];
    [sessions addObject:session];
    
    pthread_mutex_unlock(&mutex);
    
    return [self loginSession:session];
}

#pragma mark -
#pragma mark Miscellaneous helpers

- (FBTestSession *)loginSession:(FBTestSession *)session
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    FBSessionStateHandler handler = ^(FBSession *session,
                                       FBSessionState status,
                                       NSError *error) {
        STAssertTrue(!error, @"!error");

        [blocker signal];
    };
    
    [session openWithCompletionHandler:handler];
    
    BOOL success = [blocker waitWithTimeout:60];
    STAssertTrue(success, @"blocker timed out");
    STAssertTrue(session.isOpen, @"session.isOpen");
    
    return session;
}

- (void)makeTestUserInSession:(FBTestSession*)session1 friendsWithTestUserInSession:(FBTestSession*)session2 
{
    NSString *id1 = session1.testUserID;
    NSString *id2 = session2.testUserID;
    
    STAssertNotNil(id1, @"missing id1");
    STAssertNotNil(id2, @"missing id2");
    
    NSString *graphPath1 = [NSString stringWithFormat:@"me/friends/%@", id1];
    NSString *graphPath2 = [NSString stringWithFormat:@"me/friends/%@", id2];
    
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBRequest startForPostWithSession:session1
                             graphPath:graphPath2
                           graphObject:nil
                     completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         [blocker signal];
     }];
    
    [blocker wait];

    blocker = [[FBTestBlocker alloc] init];
    [FBRequest startForPostWithSession:session2
                             graphPath:graphPath1
                           graphObject:nil
                     completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
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

- (void)postAndValidateWithSession:(FBTestSession*)session graphPath:(NSString*)graphPath graphObject:(id)graphObject hasProperties:(NSArray*)propertyNames {
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

#pragma mark -

@end
 