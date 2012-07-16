/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBMyData.h"
#import "FBRequest.h"
#import "FBRequestConnection+Internal.h"
#import "FBSession.h"
#import "FBGraphUser.h"

NSString *const FBMyDataCacheIdentity = @"FBMyData";

@interface FBMyData()

- (void)unwire;
- (void)wireForSession:(FBSession *)session;
- (void)fetchPropertiesIfNeeded;
- (void)informDelegateOfProperties:(FBMyDataProperty)properties;
- (void)informDelegateOfSession;
- (void)handleActiveSessionSetNotifications:(NSNotification *)notification;
- (void)handleActiveSessionDidBecomeOpenNotifications:(NSNotification *)notification;
- (void)handleActiveSessionDidBecomeClosedNotifications:(NSNotification *)notification;

+ (NSString *)stringFBIDFromObject:(id)object;

@property (retain, nonatomic) FBRequestConnection *requestConnection;
@property (retain, nonatomic) id<FBGraphUser> me;
@property (retain, nonatomic) id friends;
@property (retain, nonatomic) id feed;
@property (copy, readwrite) NSArray *permissions;

@end

@implementation FBMyData {
    FBMyDataProperty _propertiesToFetch;
}

@synthesize delegate = _delegate,
            requestConnection = _requestConnection,
            me = _me,
            friends = _friends,
            feed = _feed,
            permissions = _permissions;

#pragma mark Lifecycle

- (id)init {
    return [self initWithPermissions:nil];
}

- (id)initWithPermissions:(NSArray *)permissions {
    self = [super init];
    if (self) {
        _propertiesToFetch = 0;
        
        self.permissions = permissions;
        
        // if our session has a cached token ready, we open it; note that
        // it is important that we open it before notification wiring is in place
        [self wireForSession:FBSession.activeSession];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleActiveSessionSetNotifications:) 
                                                     name:FBSessionDidSetActiveSessionNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleActiveSessionDidBecomeOpenNotifications:) 
                                                     name:FBSessionDidBecomeOpenActiveSessionNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleActiveSessionDidBecomeClosedNotifications:) 
                                                     name:FBSessionDidBecomeClosedActiveSessionNotification
                                                   object:nil]; 
        
        if (FBSession.activeSession.isOpen) {
            // seed our fetch to fetch me
            _propertiesToFetch = FBMyDataPropertyMe;
            
            // since we have this one property to fetch, let's fetch it if another
            // fetch is not kicked-off explicitly by the application
            [self performSelector:@selector(fetchPropertiesIfNeeded)
                       withObject:nil
                       afterDelay:.01];
        } else {
            [self unwire];
        }
    }
    return self;
}

- (void)dealloc {
    
    // removes all observers for self
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // if we have an outstanding request, cancel
    [self.requestConnection cancel];
    
    [_requestConnection release];
    [_me release];
    [_permissions release];

    [super dealloc];
}

#pragma mark Public Members

- (void)setDelegate:(id<FBMyDataDelegate>)newValue {
    if (_delegate != newValue) {
        _delegate = newValue;
        
        // whenever the delegate value changes, we schedule one initial call to inform the delegate
        // of our current state; we use a delay in order to avoid a callback in a setup or init method
        [self performSelector:@selector(informDelegateOfSession)
                   withObject:nil
                   afterDelay:.01];
    }
}

- (void)fetchProperties:(FBMyDataProperty)properties {
    // or-in the properties to fetch
    _propertiesToFetch |= properties;
    
    [self fetchPropertiesIfNeeded];
}

- (void)postStatusUpdate:(NSString *)message 
       completionHandler:(FBMyDataResultHandler)handler {
    [self postStatusUpdate:message
                     place:nil
                      tags:nil
         completionHandler:handler];
}

- (void)postStatusUpdate:(NSString *)message
                   place:(id)place
                    tags:(id<NSFastEnumeration>)tags
       completionHandler:(FBMyDataResultHandler)handler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:message forKey:@"message"];
    // if we have a place object, use it
    if (place) {
        [params setObject:[FBMyData stringFBIDFromObject:place]
                   forKey:@"place"];
    }
    // ditto tags
    if (tags) {
        NSMutableString *tagsValue = [NSMutableString string];
        NSString *format = @"%@";
        for (id tag in tags) {
            [tagsValue appendFormat:format, 
             [FBMyData stringFBIDFromObject:tag]];
            format = @",%@";
        }
        if ([tagsValue length]) {
            [params setObject:tagsValue
                       forKey:@"tags"];
        }
    }
    
    [FBRequest startWithGraphPath:@"me/feed"
                       parameters:params
                       HTTPMethod:@"POST"
                completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    handler(self, result, error);
                }];
}

- (void)postPhoto:(UIImage *)image
             name:(NSString *)name 
completionHandler:(FBMyDataResultHandler)handler {
     
    // Build the request for uploading the photo
    FBRequest *photoUploadRequest = [FBRequest requestForUploadPhoto:image];
    if (name) {
        [photoUploadRequest.parameters setObject:name forKey:@"name"];
    }
    
    // Then fire it off.
    [photoUploadRequest startWithCompletionHandler:^(FBRequestConnection *connection,
                                                     id result,
                                                     NSError *error) {        
        handler(self, result, error);
    }];
}

- (void)handleLoginPressed {
    if (FBSession.activeSession.isOpen) {
        // it would be odd to be called here if we are already open, if
        // so we just kick-off another notification to the app that we are open
        [self informDelegateOfSession];
    } else {
        // otherwise we open the session (login, or from cached tokin)
        [FBSession sessionOpenWithPermissions:self.permissions completionHandler:nil];
    }
}

- (void)handleLogoutPressed {
    [FBSession.activeSession closeAndClearTokenInformation];
}

#pragma mark Private Members, session

- (void)unwire {
    [self.requestConnection cancel];
    self.requestConnection = nil;
    self.me = nil;
    self.friends = nil;
    self.feed = nil;
}

- (void)wireForSession:(FBSession *)session {
    // if there is anything outstanding, nix it
    [self unwire];
    
    // anytime we find that our session is created with an available token
    // we open it on the spot
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [FBSession sessionOpenWithPermissions:self.permissions completionHandler:nil];
    }
}

- (void)informDelegateOfSession {
    if (FBSession.activeSession.isOpen) {
        if ([self.delegate respondsToSelector:@selector(myDataHasLoggedInUser:)]) {
            [self.delegate myDataHasLoggedInUser:self];
        }
        // any time we inform/reinform of isOpen event, we want to be sure 
        // to repass the properties if we have them
        [self informDelegateOfProperties:~0];
    } else {
        if ([self.delegate respondsToSelector:@selector(myDataHasLoggedOutUser:)]) {
            [self.delegate myDataHasLoggedOutUser:self];
        }
    }
}

- (void)handleActiveSessionSetNotifications:(NSNotification *)notification {
    // NSNotificationCenter is a global channel, so we guard against
    // unexpected uses of this notification the best we can
    if ([notification.object isKindOfClass:[FBSession class]]) {
        [self wireForSession:notification.object];
    }
}

- (void)handleActiveSessionDidBecomeOpenNotifications:(NSNotification *)notification {
    // seed our fetch to fetch me
    _propertiesToFetch = FBMyDataPropertyMe;
    
    // here we delay, in order to let any other KVO handlers to run and get an
    // opportunity to add fetches into the mix in order to pick up our property 
    // as a batch
    [self performSelector:@selector(fetchPropertiesIfNeeded)
               withObject:nil
               afterDelay:.1];
    
    [self informDelegateOfSession];
}

- (void)handleActiveSessionDidBecomeClosedNotifications:(NSNotification *)notification {
    [self unwire];
    [self informDelegateOfSession];
}

#pragma mark Private Members, properties

- (void)fetchPropertiesIfNeeded {
    // our policy is one-fetch at a time, batched if possible
    if (!_propertiesToFetch || self.requestConnection) {
        return;
    }
    
    // we will fetch from cache if possible, however all batches fetch fresh data
    BOOL attemptCacheFetch = YES;
    
    self.requestConnection = [[[FBRequestConnection alloc] init] autorelease];

    // fetching me?
    if (_propertiesToFetch & FBMyDataPropertyMe) {
        _propertiesToFetch &= ~FBMyDataPropertyMe;
        attemptCacheFetch = attemptCacheFetch && (self.me == nil);
        FBRequest *request = [FBRequest requestForMe];
        [self.requestConnection addRequest:request
                         completionHandler:^(FBRequestConnection *connection, NSMutableDictionary<FBGraphUser> *result, NSError *error) {
                             if (result) {
                                 self.me = result;
                                 [self informDelegateOfProperties:FBMyDataPropertyMe];
                             } else {
                                 self.me = nil;
                             }
                             self.requestConnection = nil;
                         }];
    }
    
    // fetching friends?
    if (_propertiesToFetch & FBMyDataPropertyFriends) {
        _propertiesToFetch &= ~FBMyDataPropertyFriends;
        attemptCacheFetch = attemptCacheFetch && (self.friends == nil);
        FBRequest *request = [FBRequest requestForMyFriends];
        [self.requestConnection addRequest:request
                         completionHandler:^(FBRequestConnection *connection, NSMutableDictionary<FBGraphUser> *result, NSError *error) {
                             if (result) {
                                 self.friends = result;
                                 [self informDelegateOfProperties:FBMyDataPropertyFriends];
                             } else {
                                 self.friends = nil;
                             }
                             self.requestConnection = nil;
                         }];
    }
    
    [self.requestConnection startWithCacheIdentity:FBMyDataCacheIdentity
                   skipRoundtripIfCached:attemptCacheFetch];
}

- (void)informDelegateOfProperties:(FBMyDataProperty)properties {
    if ([self.delegate respondsToSelector:@selector(myDataFetched:property:)]) {
        if (properties & FBMyDataPropertyMe && self.me) {
            [self.delegate myDataFetched:self
                                property:FBMyDataPropertyMe]; 
        }
        if (properties & FBMyDataPropertyFriends && self.friends) {
            [self.delegate myDataFetched:self
                                property:FBMyDataPropertyFriends]; 
        }
    }
}

#pragma mark Private Members

+ (NSString *)stringFBIDFromObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        id val = [object objectForKey:@"id"];
        if ([val isKindOfClass:[NSString class]]) {
            return val;
        }
    }
    return [object description];
}

@end
