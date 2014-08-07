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

#import "FBLikeActionController.h"

#import <QuartzCore/QuartzCore.h>

#import "FBAppEvents+Internal.h"
#import "FBDataDiskCache.h"
#import "FBDialogs+Internal.h"
#import "FBDialogs.h"
#import "FBError.h"
#import "FBErrorUtility+Internal.h"
#import "FBInternalSettings.h"
#import "FBLikeButtonPopWAV.h"
#import "FBLikeDialogParams.h"
#import "FBLogger.h"
#import "FBRequest+Internal.h"
#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBUtility.h"

NSString *const FBLikeActionControllerDidDisableNotification = @"FBLikeActionControllerDidDisableNotification";
NSString *const FBLikeActionControllerDidResetNotification = @"FBLikeActionControllerDidResetNotification";
NSString *const FBLikeActionControllerDidUpdateNotification = @"FBLikeActionControllerDidUpdateNotification";
NSString *const FBLikeActionControllerAnimatedKey = @"animated";

static NSString *const kFBLikeControllerLikeKey = @"like";
static NSString *const kFBLikeControllerRefreshKey = @"refresh";

#define kFBLikeActionControllerAnimationDelay 0.5
#define kFBLikeActionControllerSoundDelay 0.15
#define kFBLikeActionControllerAPIVersion @"v2.1"

typedef NS_ENUM(NSUInteger, FBLikeActionControllerRefreshMode) {
    FBLikeActionControllerRefreshModeInitial,
    FBLikeActionControllerRefreshModeForce,
};

typedef NS_ENUM(NSUInteger, FBLikeActionControllerRefreshState) {
    FBLikeActionControllerRefreshStateNone,
    FBLikeActionControllerRefreshStateActive,
    FBLikeActionControllerRefreshStateComplete,
};

typedef void(^fb_like_action_block)(BOOL objectIsLiked,
                                    NSString *likeCountStringWithLike,
                                    NSString *likeCountStringWithoutLike,
                                    NSString *socialSentenceWithLike,
                                    NSString *socialSentenceWithoutLike,
                                    NSString *unlikeToken,
                                    BOOL likeStateChanged,
                                    BOOL animated);

typedef void(^fb_like_action_controller_ensure_verified_object_id_completion_block)(NSString *verifiedObjectID);

@interface FBLikeActionControllerCache : NSObject
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(id)key;
@end

@implementation FBLikeActionControllerCache
{
    NSCache *_cache;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _cache = [[NSCache alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_activeSessionDidChangeWithNotification:)
                                                     name:FBSessionDidSetActiveSessionNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_activeSessionDidChangeWithNotification:)
                                                     name:FBSessionDidUnsetActiveSessionNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_activeSessionDidChangeWithNotification:)
                                                     name:FBSessionDidBecomeOpenActiveSessionNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_activeSessionDidChangeWithNotification:)
                                                     name:FBSessionDidBecomeClosedActiveSessionNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_cache release];
    [super dealloc];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [_cache objectForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(id)key
{
    [_cache setObject:object forKey:key];
}

- (void)_activeSessionDidChangeWithNotification:(NSNotification *)notification
{
    [_cache removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:FBLikeActionControllerDidResetNotification object:nil];
}

@end

@interface FBLikeActionController () <FBRequestConnectionDelegate>
@property (nonatomic, assign, getter = isContentDiscarded) BOOL contentDiscarded;
@property (nonatomic, copy) NSString *likeCountStringWithLike;
@property (nonatomic, copy) NSString *likeCountStringWithoutLike;
@property (nonatomic, assign, readwrite) BOOL objectIsLiked;
@property (nonatomic, assign, readwrite) BOOL objectIsLikedIsPending;
@property (nonatomic, assign, readwrite) BOOL objectIsLikedOnServer;
@property (nonatomic, assign, readwrite) BOOL objectIsPage;
@property (nonatomic, copy) NSString *socialSentenceWithLike;
@property (nonatomic, copy) NSString *socialSentenceWithoutLike;
@property (nonatomic, copy) NSString *unlikeToken;
@property (nonatomic, copy) NSString *verifiedObjectID;
@end

@implementation FBLikeActionController
{
    NSUInteger _contentAccessCount;
    FBSession *_session;
    FBLikeActionControllerRefreshState _refreshState;
}

#pragma mark - Helper Functions

static NSURL *FBLikeActionControllerCacheURL(NSString *objectID, FBSession *session)
{
    NSString *escapedObjectID = [objectID stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *accessToken = session.accessTokenData.accessToken;
    NSString *queryString = (accessToken ? [@"?access_token=" stringByAppendingString:accessToken] : @"");
    NSString *URLString = [NSString stringWithFormat:@"fblikecache://%@%@", escapedObjectID, queryString];
    return [NSURL URLWithString:URLString];
}

#pragma mark - Class Methods

static BOOL _fbLikeActionControllerDisabled = NO;

+ (BOOL)isDisabled
{
    return (_fbLikeActionControllerDisabled ||
            [FBSettings isPlatformCompatibilityEnabled] ||
            ![FBSettings isBetaFeatureEnabled:FBBetaFeaturesLikeButton]);
}

+ (instancetype)likeActionControllerForObjectID:(NSString *)objectID
{
    if (!objectID) {
        return nil;
    }
    static FBLikeActionControllerCache *_cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cache = [[FBLikeActionControllerCache alloc] init];
    });
    @synchronized(self) {
        FBLikeActionController *controller = _cache[objectID];
        FBSession *session = [FBSession activeSession];
        BOOL controllerIsNew = NO;
        if (!controller) {
            NSData *cacheData = [[FBDataDiskCache sharedCache] dataForURL:FBLikeActionControllerCacheURL(objectID, session)];
            if (cacheData) {
                id object = [NSKeyedUnarchiver unarchiveObjectWithData:cacheData];
                if ([object isKindOfClass:[self class]]) {
                    controller = object;
                    controllerIsNew = YES;
                }
            }
        }
        if (!controller) {
            controller = [[[self alloc] initWithObjectID:objectID session:session] autorelease];
            controllerIsNew = YES;
        }
        if (controllerIsNew) {
            _cache[objectID] = controller;
        } else {
            [controller beginContentAccess];
        }
        [controller _refreshWithMode:FBLikeActionControllerRefreshModeInitial];
        return controller;
    }
}

#pragma mark - Object Lifecycle

- (instancetype)initWithObjectID:(NSString *)objectID session:(FBSession *)session
{
    if ((self = [super init])) {
        _objectID = [objectID copy];
        _session = [session retain];

        _contentAccessCount = 1;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithObjectID:nil session:nil];
}

- (void)dealloc
{
    [_objectID release];
    [_session release];
    [_socialSentenceWithLike release];
    [_socialSentenceWithoutLike release];
    [_unlikeToken release];
    [_verifiedObjectID release];
    [super dealloc];
}

#pragma mark - NSCoding

static NSString *const kFBLikeActionControllerLikeCountStringWithLikeKey = @"likeCountStringWithLike";
static NSString *const kFBLikeActionControllerLikeCountStringWithoutLikeKey = @"likeCountStringWithoutLike";
static NSString *const kFBLikeActionControllerObjectIDKey = @"objectID";
static NSString *const kFBLikeActionControllerObjectIsLikedKey = @"objectIsLiked";
static NSString *const kFBLikeActionControllerSocialSentenceWithLikeKey = @"socialSentenceWithLike";
static NSString *const kFBLikeActionControllerSocialSentenceWithoutLikeKey = @"socialSentenceWithoutLike";
static NSString *const kFBLikeActionControllerUnlikeTokenKey = @"unlikeToken";
static NSString *const kFBLikeActionControllerVersionKey = @"version";

static const NSUInteger kFBLikeActionControllerCodingVersion = 2;

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ([decoder decodeIntegerForKey:kFBLikeActionControllerVersionKey] != kFBLikeActionControllerCodingVersion) {
        return nil;
    }

    NSString *objectID = [decoder decodeObjectOfClass:[NSString class] forKey:kFBLikeActionControllerObjectIDKey];
    if (!objectID) {
        return nil;
    }

    if ((self = [super init])) {
        _objectID = [objectID copy];
        _session = [[FBSession activeSession] retain];

        _likeCountStringWithLike = [[decoder decodeObjectOfClass:[NSString class]
                                                          forKey:kFBLikeActionControllerLikeCountStringWithLikeKey] copy];
        _likeCountStringWithoutLike = [[decoder decodeObjectOfClass:[NSString class]
                                                             forKey:kFBLikeActionControllerLikeCountStringWithoutLikeKey] copy];
        _objectIsLiked = [decoder decodeBoolForKey:kFBLikeActionControllerObjectIsLikedKey];
        _socialSentenceWithLike = [[decoder decodeObjectOfClass:[NSString class]
                                                         forKey:kFBLikeActionControllerSocialSentenceWithLikeKey] copy];
        _socialSentenceWithoutLike = [[decoder decodeObjectOfClass:[NSString class]
                                                            forKey:kFBLikeActionControllerSocialSentenceWithoutLikeKey] copy];
        _unlikeToken = [[decoder decodeObjectOfClass:[NSString class] forKey:kFBLikeActionControllerUnlikeTokenKey] copy];

        _contentAccessCount = 1;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_likeCountStringWithLike forKey:kFBLikeActionControllerLikeCountStringWithLikeKey];
    [coder encodeObject:_likeCountStringWithoutLike forKey:kFBLikeActionControllerLikeCountStringWithoutLikeKey];
    [coder encodeObject:_objectID forKey:kFBLikeActionControllerObjectIDKey];
    [coder encodeBool:_objectIsLiked forKey:kFBLikeActionControllerObjectIsLikedKey];
    [coder encodeObject:_socialSentenceWithLike forKey:kFBLikeActionControllerSocialSentenceWithLikeKey];
    [coder encodeObject:_socialSentenceWithoutLike forKey:kFBLikeActionControllerSocialSentenceWithoutLikeKey];
    [coder encodeObject:_unlikeToken forKey:kFBLikeActionControllerUnlikeTokenKey];
    [coder encodeInteger:kFBLikeActionControllerCodingVersion forKey:kFBLikeActionControllerVersionKey];
}

#pragma mark - Properties

- (NSString *)likeCountString
{
    return (self.objectIsLiked ? self.likeCountStringWithLike : self.likeCountStringWithoutLike);
}

- (NSString *)socialSentence
{
    return (self.objectIsLiked ? self.socialSentenceWithLike : self.socialSentenceWithoutLike);
}

#pragma mark - Public API

- (void)refresh
{
    [self _refreshWithMode:FBLikeActionControllerRefreshModeForce];
}

- (void)toggleLikeWithSoundEnabled:(BOOL)soundEnabled analyticsParameters:(NSDictionary *)analyticsParameters
{
    [FBAppEvents logImplicitEvent:FBAppEventNameFBLikeControlDidTap
                       valueToSum:nil
                       parameters:analyticsParameters
                          session:_session];

    [self _setExecuting:YES forKey:kFBLikeControllerLikeKey];

    BOOL useOGLike = [self _useOGLike];
    BOOL deferred = !useOGLike;

    fb_like_action_block updateBlock = ^(BOOL objectIsLiked,
                                         NSString *likeCountStringWithLike,
                                         NSString *likeCountStringWithoutLike,
                                         NSString *socialSentenceWithLike,
                                         NSString *socialSentenceWithoutLike,
                                         NSString *unlikeToken,
                                         BOOL likeStateChanged,
                                         BOOL animated){
        [self _updateWithObjectIsLiked:objectIsLiked
               likeCountStringWithLike:likeCountStringWithLike
            likeCountStringWithoutLike:likeCountStringWithoutLike
                socialSentenceWithLike:socialSentenceWithLike
             socialSentenceWithoutLike:socialSentenceWithoutLike
                           unlikeToken:unlikeToken
                          soundEnabled:soundEnabled && likeStateChanged
                              animated:animated
                              deferred:deferred];
    };

    BOOL objectIsLiked = !self.objectIsLiked;

    // optimistically update if using og.like (FAS will defer the update)
    if (useOGLike) {
        updateBlock(objectIsLiked,
                    self.likeCountStringWithLike,
                    self.likeCountStringWithoutLike,
                    self.socialSentenceWithLike,
                    self.socialSentenceWithoutLike,
                    self.unlikeToken,
                    YES,
                    YES);
        if (self.objectIsLikedIsPending) {
            return;
        }
    }

    if (objectIsLiked) {
        if (useOGLike) {
            [self _publishLikeWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        } else {
            [self _presentLikeDialogWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        }
    } else {
        if (useOGLike && self.unlikeToken) {
            [self _publishUnlikeWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        } else {
            [self _presentLikeDialogWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        }
    }
}

#pragma mark - NSDiscardableContent

- (BOOL)beginContentAccess
{
    self.contentDiscarded = NO;
    _contentAccessCount++;
    return YES;
}

- (void)endContentAccess
{
    _contentAccessCount--;
}

- (void)discardContentIfPossible
{
    if (_contentAccessCount == 0) {
        self.contentDiscarded = YES;
    }
}

- (BOOL)isContentDiscarded
{
    return _contentDiscarded;
}

#pragma mark - Helper Methods

static void FBLikeActionControllerLogError(NSString *currentAction, NSString *objectID, FBSession *session, NSError *error)
{
    NSDictionary *parameters = @{
                                 @"object_id": objectID,
                                 @"current_action": currentAction,
                                 @"error": [FBUtility simpleJSONEncode:[FBErrorUtility jsonDictionaryForError:error]],
                                 };
    NSString *eventName = ([FBErrorUtility errorIsNetworkError:error] ?
                           FBAppEventNameFBLikeControlNetworkUnavailable :
                           FBAppEventNameFBLikeControlError);
    [FBAppEvents logImplicitEvent:eventName
                       valueToSum:nil
                       parameters:parameters
                          session:session];
}

typedef void(^fb_like_action_controller_get_engagement_completion_block)(BOOL success,
                                                                         NSString *likeCountStringWithLike,
                                                                         NSString *likeCountStringWithoutLike,
                                                                         NSString *socialSentenceWithLike,
                                                                         NSString *socialSentenceWithoutLike);
static void FBLikeActionControllerAddGetEngagementRequest(FBSession *session,
                                                          FBRequestConnection *connection,
                                                          NSString *objectID,
                                                          fb_like_action_controller_get_engagement_completion_block completionHandler)
{
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:objectID
                                                 parameters:@{
                                                              @"fields": @"engagement.fields(count_string_with_like,count_string_without_like,social_sentence_with_like,social_sentence_without_like)",
                                                              }
                                                 HTTPMethod:@"GET"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        BOOL success = NO;
        NSString *likeCountStringWithLike = nil;
        NSString *likeCountStringWithoutLike = nil;
        NSString *socialSentenceWithLike = nil;
        NSString *socialSentenceWithoutLike = nil;
        if (error) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorFBRequests
                            formatString:@"Error fetching engagement for %@: %@", objectID, error];
            FBLikeActionControllerLogError(@"get_engagement", objectID, session, error);
        } else {
            success = YES;
            likeCountStringWithLike = [result valueForKeyPath:@"engagement.count_string_with_like"];
            likeCountStringWithoutLike = [result valueForKeyPath:@"engagement.count_string_without_like"];
            socialSentenceWithLike = [result valueForKeyPath:@"engagement.social_sentence_with_like"];
            socialSentenceWithoutLike = [result valueForKeyPath:@"engagement.social_sentence_without_like"];
        }
        if (completionHandler != NULL) {
            completionHandler(success,
                              likeCountStringWithLike,
                              likeCountStringWithoutLike,
                              socialSentenceWithLike,
                              socialSentenceWithoutLike);
        }
    }];
    [request release];
}

typedef void(^fb_like_action_controller_get_object_id_completion_block)(NSString *objectID);
static void FBLikeActionControllerAddGetOGObjectIDRequest(FBSession *session,
                                                          FBRequestConnection *connection,
                                                          NSString *objectID,
                                                          fb_like_action_controller_get_object_id_completion_block completionHandler)
{
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:@""
                                                 parameters:@{
                                                              @"fields": @"og_object.fields(id)",
                                                              @"id": objectID,
                                                              }
                                                 HTTPMethod:@"GET"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        NSString *verifiedObjectID = [result valueForKeyPath:@"og_object.id"];
        if (completionHandler != NULL) {
            completionHandler(verifiedObjectID);
        }
    }];
    [request release];
}

static void FBLikeActionControllerAddGetPageObjectIDRequest(FBSession *session,
                                                            FBRequestConnection *connection,
                                                            NSString *objectID,
                                                            fb_like_action_controller_get_object_id_completion_block completionHandler)
{
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:@""
                                                 parameters:@{
                                                              @"fields": @"id",
                                                              @"id": objectID,
                                                              }
                                                 HTTPMethod:@"GET"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        NSString *verifiedObjectID = result[@"id"];
        if (completionHandler != NULL) {
            completionHandler(verifiedObjectID);
        }
    }];
    [request release];
}

typedef void(^fb_like_action_controller_get_og_object_like_completion_block)(BOOL success,
                                                                             BOOL objectIsLiked,
                                                                             NSString *unlikeToken);
static void FBLikeActionControllerAddGetOGObjectLikeRequest(FBSession *session,
                                                            FBRequestConnection *connection,
                                                            NSString *objectID,
                                                            fb_like_action_controller_get_og_object_like_completion_block completionHandler)
{
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:@"me/og.likes"
                                                 parameters:@{
                                                              @"fields": @"id,application",
                                                              @"object": objectID,
                                                              }
                                                 HTTPMethod:@"GET"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        BOOL success = NO;
        BOOL objectIsLiked = NO;
        NSString *unlikeToken = nil;
        if (error) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorFBRequests
                            formatString:@"Error fetching like state for %@: %@", objectID, error];
            FBLikeActionControllerLogError(@"get_og_object_like", objectID, session, error);
        } else {
            success = YES;
            NSArray *dataSet = result[@"data"];
            for (NSDictionary *data in dataSet) {
                objectIsLiked = YES;
                NSString *applicationID = [data valueForKeyPath:@"application.id"];
                if ([session.appID isEqualToString:applicationID]) {
                    unlikeToken = data[@"id"];
                    break;
                }
            }
        }
        if (completionHandler != NULL) {
            completionHandler(success, objectIsLiked, unlikeToken);
        }
    }];
    [request release];
}

typedef void(^fb_like_action_controller_publish_like_completion_block)(BOOL success, NSString *unlikeToken);
static void FBLikeActionControllerAddPublishLikeRequest(FBSession *session,
                                                        FBRequestConnection *connection,
                                                        NSString *objectID,
                                                        fb_like_action_controller_publish_like_completion_block completionHandler)
{
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:@"me/og.likes"
                                                 parameters:@{ @"object": objectID }
                                                 HTTPMethod:@"POST"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        BOOL success = NO;
        NSString *unlikeToken = nil;
        if (error) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorFBRequests
                            formatString:@"Error liking object %@: %@", objectID, error];
            FBLikeActionControllerLogError(@"publish_like", objectID, session, error);
        } else {
            success = YES;
            unlikeToken = result[@"id"];
        }
        if (completionHandler != NULL) {
            completionHandler(success, unlikeToken);
        }
    }];
    [request release];
}

typedef void(^fb_like_action_controller_publish_unlike_completion_block)(BOOL success);
static void FBLikeActionControllerAddPublishUnlikeRequest(FBSession *session,
                                                          FBRequestConnection *connection,
                                                          NSString *unlikeToken,
                                                          fb_like_action_controller_publish_unlike_completion_block completionHandler)
{
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:unlikeToken
                                                 parameters:nil
                                                 HTTPMethod:@"DELETE"];
    [connection addRequest:request completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        BOOL success = NO;
        if (error) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorFBRequests
                            formatString:@"Error unliking object with unlike token %@: %@", unlikeToken, error];
            FBLikeActionControllerLogError(@"publish_unlike", unlikeToken, session, error);
        } else {
            success = YES;
        }
        if (completionHandler != NULL) {
            completionHandler(success);
        }
    }];
    [request release];
}

static void FBLikeActionControllerAddRefreshRequests(FBSession *session,
                                                     FBRequestConnection *connection,
                                                     NSString *objectID,
                                                     fb_like_action_block completionHandler)
{
    __block BOOL objectIsLiked = NO;
    __block NSString *likeCountStringWithLike = nil;
    __block NSString *likeCountStringWithoutLike = nil;
    __block NSString *socialSentenceWithLike = nil;
    __block NSString *socialSentenceWithoutLike = nil;
    __block NSString *unlikeToken = nil;

    void(^handleResults)(void) = ^{
        if (completionHandler != NULL) {
            completionHandler(objectIsLiked,
                              likeCountStringWithLike,
                              likeCountStringWithoutLike,
                              socialSentenceWithLike,
                              socialSentenceWithoutLike,
                              unlikeToken,
                              NO,
                              NO);
        }

        [likeCountStringWithLike release];
        [likeCountStringWithoutLike release];
        [socialSentenceWithLike release];
        [socialSentenceWithoutLike release];
        [unlikeToken release];
    };

    FBLikeActionControllerAddGetOGObjectLikeRequest(session, connection, objectID, ^(BOOL success,
                                                                                     BOOL innerObjectIsLiked,
                                                                                     NSString *innerUnlikeToken) {
        if (success) {
            objectIsLiked = objectIsLiked || innerObjectIsLiked;
            if (innerUnlikeToken) {
                unlikeToken = [innerUnlikeToken copy];
            }
        }
    });

    FBLikeActionControllerAddGetEngagementRequest(session, connection, objectID, ^(BOOL success,
                                                                                   NSString *innerLikeCountStringWithLike,
                                                                                   NSString *innerLikeCountStringWithoutLike,
                                                                                   NSString *innerSocialSentenceWithLike,
                                                                                   NSString *innerSocialSentenceWithoutLike) {
        if (success) {
            likeCountStringWithLike = [innerLikeCountStringWithLike copy];
            likeCountStringWithoutLike = [innerLikeCountStringWithoutLike copy];
            socialSentenceWithLike = [innerSocialSentenceWithLike copy];
            socialSentenceWithoutLike = [innerSocialSentenceWithoutLike copy];

            handleResults();
        }
    });
}


- (void)_ensureVerifiedObjectID:(fb_like_action_controller_ensure_verified_object_id_completion_block)completion
{
    __block NSString *verifiedObjectID = self.verifiedObjectID;
    if (verifiedObjectID) {
        if (completion != NULL) {
            completion(verifiedObjectID);
        }
        return;
    }

    __block BOOL objectIsPage = NO;
    void(^handleResults)(void) = ^{
        self.verifiedObjectID = verifiedObjectID;
        self.objectIsPage = objectIsPage;

        if (completion != NULL) {
            completion(verifiedObjectID);
        }
        [verifiedObjectID release];
    };
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection overrideVersionPartWith:kFBLikeActionControllerAPIVersion];
    FBLikeActionControllerAddGetOGObjectIDRequest(_session, connection, self.objectID, ^(NSString *innerVerifiedObjectID) {
        if (innerVerifiedObjectID) {
            verifiedObjectID = [innerVerifiedObjectID copy];
        } else {
            objectIsPage = YES;
        }
    });
    FBLikeActionControllerAddGetPageObjectIDRequest(_session, connection, self.objectID, ^(NSString *innerVerifiedObjectID) {
        if (objectIsPage && innerVerifiedObjectID) {
            verifiedObjectID = [innerVerifiedObjectID copy];
        }

        handleResults();
    });
    [connection start];
    [connection release];
}

- (void)_presentLikeDialogWithUpdateBlock:(fb_like_action_block)updateBlock
                      analyticsParameters:(NSDictionary *)analyticsParameters
{
    FBLikeDialogParams *params = [[[FBLikeDialogParams alloc] init] autorelease];
    params.objectID = _objectID;

    if (![FBDialogs canPresentLikeDialog]) {
        [FBAppEvents logImplicitEvent:FBAppEventNameFBLikeControlCannotPresentDialog
                           valueToSum:nil
                           parameters:analyticsParameters
                              session:_session];
        return;
    }
    [FBAppEvents logImplicitEvent:FBAppEventNameFBLikeControlDidPresentDialog
                       valueToSum:nil
                       parameters:analyticsParameters
                          session:_session];

    [FBDialogs presentLikeDialogWithParams:params clientState:nil handler:^(FBAppCall *call,
                                                                            NSDictionary *results,
                                                                            NSError *error) {
        if (error) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorFBRequests
                            formatString:@"Like dialog error for %@: %@", _objectID, error];

            if ([error.userInfo[@"error_reason"] isEqualToString:@"dialog_disabled"]) {
                _fbLikeActionControllerDisabled = YES;

                [FBAppEvents logImplicitEvent:FBAppEventNameFBLikeControlDidDisable
                                   valueToSum:nil
                                   parameters:analyticsParameters
                                      session:_session];

                [[NSNotificationCenter defaultCenter] postNotificationName:FBLikeActionControllerDidDisableNotification
                                                                    object:self
                                                                  userInfo:nil];
            } else {
                FBLikeActionControllerLogError(@"present_dialog", _objectID, _session, error);
            }
        } else {
            NSNumber *objectIsLikedNumber = results[@"object_is_liked"];
            NSString *likeCountString = results[@"like_count_string"];
            NSString *socialSentence = results[@"social_sentence"] ?: self.socialSentence;
            NSString *unlikeToken = results[@"unlike_token"] ?: self.unlikeToken;
            BOOL likeStateChanged = ![results[@"completionGesture"] isEqualToString:@"cancel"];

            if (([objectIsLikedNumber isKindOfClass:[NSNumber class]]) &&
                (!likeCountString || [likeCountString isKindOfClass:[NSString class]]) &&
                (!socialSentence || [socialSentence isKindOfClass:[NSString class]]) &&
                (!unlikeToken || [unlikeToken isKindOfClass:[NSString class]])) {
                if (updateBlock != NULL) {
                    // we do not need to specify values for with/without like, since we will fast-app-switch to change
                    // the value
                    BOOL objectIsLiked = (objectIsLikedNumber ? [objectIsLikedNumber boolValue] : self.objectIsLiked);
                    updateBlock(objectIsLiked,
                                likeCountString,
                                likeCountString,
                                socialSentence,
                                socialSentence,
                                unlikeToken,
                                likeStateChanged,
                                YES);
                }
            }
        }

        [self _setExecuting:NO forKey:kFBLikeControllerLikeKey];
    }];
}

- (void)_publishIfNeededWithUpdateBlock:(fb_like_action_block)updateBlock
                    analyticsParameters:(NSDictionary *)analyticsParameters
{
    BOOL objectIsLiked = self.objectIsLiked;
    if (self.objectIsLikedOnServer != objectIsLiked) {
        if (objectIsLiked) {
            [self _publishLikeWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        } else {
            [self _publishUnlikeWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        }
    }
}

- (void)_publishLikeWithUpdateBlock:(fb_like_action_block)updateBlock
                analyticsParameters:(NSDictionary *)analyticsParameters
{
    self.objectIsLikedIsPending = YES;
    [self _ensureVerifiedObjectID:^(NSString *verifiedObjectID) {
        FBRequestConnection *connection = [[FBRequestConnection alloc] init];
        [connection overrideVersionPartWith:kFBLikeActionControllerAPIVersion];
        fb_like_action_controller_publish_like_completion_block completionHandler = ^(BOOL success,
                                                                                      NSString *unlikeToken) {
            if (success) {
                self.objectIsLikedIsPending = NO;
                self.objectIsLikedOnServer = YES;
                self.unlikeToken = unlikeToken;
                if (updateBlock != NULL) {
                    updateBlock(self.objectIsLiked,
                                self.likeCountStringWithLike,
                                self.likeCountStringWithoutLike,
                                self.socialSentenceWithLike,
                                self.socialSentenceWithoutLike,
                                self.unlikeToken,
                                NO,
                                NO);
                }
                [self _publishIfNeededWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
            } else {
                [self _presentLikeDialogWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
            }
        };
        FBLikeActionControllerAddPublishLikeRequest(_session, connection, verifiedObjectID, completionHandler);
        [connection start];
        [connection release];
    }];
}

- (void)_publishUnlikeWithUpdateBlock:(fb_like_action_block)updateBlock
                  analyticsParameters:(NSDictionary *)analyticsParameters
{
    self.objectIsLikedIsPending = YES;
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection overrideVersionPartWith:kFBLikeActionControllerAPIVersion];
    fb_like_action_controller_publish_unlike_completion_block completionHandler = ^(BOOL success) {
        if (success) {
            self.objectIsLikedIsPending = NO;
            self.objectIsLikedOnServer = NO;
            self.unlikeToken = nil;
            if (updateBlock != NULL) {
                updateBlock(self.objectIsLiked,
                            self.likeCountStringWithLike,
                            self.likeCountStringWithoutLike,
                            self.socialSentenceWithLike,
                            self.socialSentenceWithoutLike,
                            self.unlikeToken,
                            NO,
                            NO);
            }
            [self _publishIfNeededWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        } else {
            [self _presentLikeDialogWithUpdateBlock:updateBlock analyticsParameters:analyticsParameters];
        }
    };
    FBLikeActionControllerAddPublishUnlikeRequest(_session, connection, self.unlikeToken, completionHandler);
    [connection start];
    [connection release];
}

- (void)_refreshWithMode:(FBLikeActionControllerRefreshMode)mode
{
    switch (mode) {
        case FBLikeActionControllerRefreshModeForce:{
            // if we're already refreshing, skip
            if (_refreshState == FBLikeActionControllerRefreshStateActive) {
                return;
            }
            break;
        }
        case FBLikeActionControllerRefreshModeInitial:{
            // if we've already started any refresh, skip this
            if (_refreshState != FBLikeActionControllerRefreshStateNone) {
                return;
            }
            break;
        }
    }

    // You must be logged in to fetch the like status
    if (!_session.accessTokenData) {
        return;
    }

    [self _setExecuting:YES forKey:kFBLikeControllerRefreshKey];
    _refreshState = FBLikeActionControllerRefreshStateActive;

    [self _ensureVerifiedObjectID:^(NSString *verifiedObjectID) {
        FBRequestConnection *connection = [[FBRequestConnection alloc] init];
        [connection overrideVersionPartWith:kFBLikeActionControllerAPIVersion];
        FBLikeActionControllerAddRefreshRequests(_session,
                                                 connection,
                                                 verifiedObjectID,
                                                 ^(BOOL objectIsLiked,
                                                   NSString *likeCountStringWithLike,
                                                   NSString *likeCountStringWithoutLike,
                                                   NSString *socialSentenceWithLike,
                                                   NSString *socialSentenceWithoutLike,
                                                   NSString *unlikeToken,
                                                   BOOL likeStateChanged,
                                                   BOOL animated) {
                                                     [self _updateWithObjectIsLiked:objectIsLiked
                                                            likeCountStringWithLike:likeCountStringWithLike
                                                         likeCountStringWithoutLike:likeCountStringWithoutLike
                                                             socialSentenceWithLike:socialSentenceWithLike
                                                          socialSentenceWithoutLike:socialSentenceWithoutLike
                                                                        unlikeToken:unlikeToken
                                                                       soundEnabled:NO
                                                                           animated:animated
                                                                           deferred:NO];
                                                     [self _setExecuting:NO forKey:kFBLikeControllerRefreshKey];
                                                     _refreshState = FBLikeActionControllerRefreshStateComplete;
                                                 });
        [connection start];
        [connection release];
    }];
}

- (void)_serialize
{
    NSData *cacheData = [NSKeyedArchiver archivedDataWithRootObject:self];
    [[FBDataDiskCache sharedCache] setData:cacheData forURL:FBLikeActionControllerCacheURL(_objectID, _session)];
}

- (void)_setExecuting:(BOOL)executing forKey:(NSString *)key
{
    static NSMapTable *_executing = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _executing = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    });

    NSString *objectKey = [NSString stringWithFormat:@"%@:%@", _objectID, key];
    if (executing) {
        [self beginContentAccess];
        [_executing setObject:self forKey:objectKey];
    } else {
        [_executing removeObjectForKey:objectKey];
        [self endContentAccess];
    }
}

- (void)_updateWithObjectIsLiked:(BOOL)objectIsLiked
         likeCountStringWithLike:(NSString *)likeCountStringWithLike
      likeCountStringWithoutLike:(NSString *)likeCountStringWithoutLike
          socialSentenceWithLike:(NSString *)socialSentenceWithLike
       socialSentenceWithoutLike:(NSString *)socialSentenceWithoutLike
                     unlikeToken:(NSString *)unlikeToken
                    soundEnabled:(BOOL)soundEnabled
                        animated:(BOOL)animated
                        deferred:(BOOL)deferred
{
    BOOL(^contentChanged)(void) = ^{
        return (BOOL)!((self.objectIsLiked == objectIsLiked) &&
                       ((self.likeCountStringWithLike == likeCountStringWithLike) ||
                        [self.likeCountStringWithLike isEqualToString:likeCountStringWithLike]) &&
                       ((self.likeCountStringWithoutLike == likeCountStringWithoutLike) ||
                        [self.likeCountStringWithoutLike isEqualToString:likeCountStringWithoutLike]) &&
                       ((self.socialSentenceWithLike == socialSentenceWithLike) ||
                        [self.socialSentenceWithLike isEqualToString:socialSentenceWithLike]) &&
                       ((self.socialSentenceWithoutLike == socialSentenceWithoutLike) ||
                        [self.socialSentenceWithoutLike isEqualToString:socialSentenceWithoutLike]) &&
                       ((self.unlikeToken == unlikeToken) || [self.unlikeToken isEqualToString:unlikeToken]));
    };

    // check if the like state changed and only animate if it did
    if (!contentChanged()) {
        return;
    }

    void(^updateBlock)(void) = ^{
        if (!contentChanged()) {
            return;
        }

        // if only meta data changed, don't animate
        BOOL objectIsLikedChanged = (self.objectIsLiked != objectIsLiked);

        self.objectIsLiked = objectIsLiked;
        self.likeCountStringWithLike = likeCountStringWithLike;
        self.likeCountStringWithoutLike = likeCountStringWithoutLike;
        self.socialSentenceWithLike = socialSentenceWithLike;
        self.socialSentenceWithoutLike = socialSentenceWithoutLike;
        self.unlikeToken = unlikeToken;

        FBLikeButtonPopWAV *likeSound = (objectIsLikedChanged && objectIsLiked && soundEnabled ? [FBLikeButtonPopWAV sharedLoader] : nil);

        void(^notificationBlock)(void) = ^{
            if (likeSound) {
                dispatch_time_t soundPopTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kFBLikeActionControllerSoundDelay * NSEC_PER_SEC));
                dispatch_after(soundPopTime, dispatch_get_main_queue(), ^(void){
                    [likeSound playSound];
                });
            }
            NSDictionary *userInfo = @{FBLikeActionControllerAnimatedKey: @(animated)};
            [[NSNotificationCenter defaultCenter] postNotificationName:FBLikeActionControllerDidUpdateNotification
                                                                object:self
                                                              userInfo:userInfo];
        };

        notificationBlock();
        [self _serialize];
    };

    // if only meta data changed, don't defer
    if (deferred && (self.objectIsLiked != objectIsLiked)) {
        double delayInSeconds = kFBLikeActionControllerAnimationDelay;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), updateBlock);
    } else {
        updateBlock();
    }
}

- (BOOL)_useOGLike
{
    NSArray *permissions = _session.permissions;
    return (!self.objectIsPage &&
            self.verifiedObjectID &&
            permissions &&
            ([permissions indexOfObject:@"publish_actions"] != NSNotFound));
}

@end
