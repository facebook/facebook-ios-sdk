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
#import "FBSession.h"
#import "FBTestBlocker.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"

static NSMutableDictionary *mapTestClassesToSessions;
// Concurrency not an issue today, but guard our static global in any case.
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

@interface FBTests ()

@end

@implementation FBTests

+ (void)setUp
{
    pthread_mutex_lock(&mutex);
    
    if (!mapTestClassesToSessions) {
        mapTestClassesToSessions = [[NSMutableDictionary alloc] init];
    }
    [mapTestClassesToSessions setObject:[[NSMutableArray alloc] init] 
                                 forKey:self]; 
                                 
    pthread_mutex_unlock(&mutex);
}

+ (void)tearDown
{
    pthread_mutex_lock(&mutex);
    
    NSMutableArray *sessions = [mapTestClassesToSessions objectForKey:self];
    [mapTestClassesToSessions removeObjectForKey:self];

    pthread_mutex_unlock(&mutex);

    for (FBSession *session in sessions) {
        [session invalidate];
    }
    [sessions release];
} 

- (FBSession *)loginTestUserWithPermissions:(NSString *)firstPermission, ...
{
    NSMutableArray *permissions = [[[NSMutableArray alloc] init] autorelease];
    
    if (firstPermission) {
        [permissions addObject:firstPermission];
        
        id vaPermission;
        va_list vaArguments;
        va_start(vaArguments, firstPermission);
        while ((vaPermission = va_arg(vaArguments, id))) {
            [permissions addObject:vaPermission];
        }
        va_end(vaArguments);
    }
    
    FBSession *session = [FBSession sessionForUnitTestingWithPermissions:permissions];
    
    pthread_mutex_lock(&mutex);
    
    NSMutableArray *sessions = [mapTestClassesToSessions objectForKey:[self class]];
    [sessions addObject:session];
    
    pthread_mutex_unlock(&mutex);
    
    return [self loginSession:session];
}

- (FBSession *)loginSession:(FBSession *)session
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    FBSessionStatusHandler handler = ^(FBSession *session,
                                       FBSessionState status,
                                       NSError *error) {
        STAssertTrue(!error, @"!error");

        [blocker signal];
        // We assume we're only being waited on the first time.
        blocker = nil;
    };
    
    [session loginWithCompletionHandler:handler];
    
    [blocker wait];
    STAssertTrue(session.isValid, @"session.isValid");
    
    return session;
}

- (void)makeTestUserInSession:(FBSession*)session1 friendsWithTestUserInSession:(FBSession*)session2 
{
    NSString *id1 = [FBSession testUserIDForSession:session1];
    NSString *id2 = [FBSession testUserIDForSession:session2];
    
    STAssertNotNil(id1, @"missing id1");
    STAssertNotNil(id2, @"missing id2");
    
    NSString *graphPath1 = [NSString stringWithFormat:@"me/friends/%@", id1];
    NSString *graphPath2 = [NSString stringWithFormat:@"me/friends/%@", id2];
    
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    FBRequestConnection *conn = [FBRequest connectionForPostWithSession:session1
                                                              graphPath:graphPath2
                                                            graphObject:nil
                                                      completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            STAssertTrue(!error, @"!error");
            [blocker signal];
        }];
    
    [conn start];
    [blocker wait];

    blocker = [[FBTestBlocker alloc] init];
    conn = [FBRequest connectionForPostWithSession:session2
                                         graphPath:graphPath1
                                       graphObject:nil
                                 completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            STAssertTrue(!error, @"!error");
            [blocker signal];
        }];
    
    [conn start];
    [blocker wait];
}

@end
 