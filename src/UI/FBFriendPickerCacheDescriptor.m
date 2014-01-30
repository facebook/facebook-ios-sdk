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

#import "FBFriendPickerCacheDescriptor.h"

#import "FBFriendPickerViewController+Internal.h"
#import "FBGraphObjectPagingLoader.h"
#import "FBGraphObjectTableDataSource.h"
#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBSession.h"

@interface FBFriendPickerCacheDescriptor () <FBGraphObjectPagingLoaderDelegate>

@property (nonatomic, readwrite, copy) NSSet *fieldsForRequest;
@property (nonatomic, readwrite, copy) NSString *userID;
@property (nonatomic, readwrite, retain) FBGraphObjectPagingLoader *loader;

// these properties are only used by unit tests, and should not be removed or made public
@property (nonatomic, readwrite, assign) BOOL hasCompletedFetch;
@property (nonatomic, readwrite, assign) BOOL usePageLimitOfOne;
- (void)setUsePageLimitOfOne;

@end

@implementation FBFriendPickerCacheDescriptor

- (instancetype)init {
    return [self initWithUserID:nil
               fieldsForRequest:nil];
}

- (instancetype)initWithUserID:(NSString *)userID {
    return [self initWithUserID:userID
               fieldsForRequest:nil];
}

- (instancetype)initWithFieldsForRequest:(NSSet *)fieldsForRequest {
    return [self initWithUserID:nil
               fieldsForRequest:fieldsForRequest];
}

- (instancetype)initWithUserID:(NSString *)userID fieldsForRequest:(NSSet *)fieldsForRequest {
    self = [super init];
    if (self) {
        self.fieldsForRequest = fieldsForRequest ? fieldsForRequest : [NSSet set];
        self.userID = userID;
        self.hasCompletedFetch = NO;
        self.usePageLimitOfOne = NO;
    }
    return self;
}

- (void)dealloc {
    self.fieldsForRequest = nil;
    self.userID = nil;
    self.loader = nil;
    [super dealloc];
}

- (void)prefetchAndCacheForSession:(FBSession *)session {
    // Friend queries require a session, so do nothing if we don't have one.
    if (session == nil) {
        return;
    }

    // datasource has some field ownership, so we need one here
    FBGraphObjectTableDataSource *datasource = [[[FBGraphObjectTableDataSource alloc] init] autorelease];
    datasource.groupByField = @"name";

    // me or one of my friends that also uses the app
    NSString *user = self.userID;
    if (!user) {
        user = @"me";
    }

    // create the request object that we will start with
    FBRequest *request = [FBFriendPickerViewController requestWithUserID:user
                                                                  fields:self.fieldsForRequest
                                                              dataSource:datasource
                                                                 session:session];

    // this property supports unit testing
    if(self.usePageLimitOfOne) {
        [request.parameters setObject:@"1"
                               forKey:@"limit"];
    }

    self.loader.delegate = nil;
    self.loader = [[[FBGraphObjectPagingLoader alloc] initWithDataSource:datasource
                                                              pagingMode:FBGraphObjectPagingModeImmediateViewless]
                   autorelease];
    self.loader.session = session;

    self.loader.delegate = self;

    // make sure we are around to handle the delegate call
    [self retain];

    // seed the cache
    [self.loader startLoadingWithRequest:request
                           cacheIdentity:FBFriendPickerCacheIdentity
                   skipRoundtripIfCached:NO];
}

- (void)setUsePageLimitOfOne {
    self.usePageLimitOfOne = YES;
}

- (void)pagingLoaderDidFinishLoading:(FBGraphObjectPagingLoader *)pagingLoader {
    self.loader.delegate = nil;
    self.loader = nil;
    self.hasCompletedFetch = YES;

    // this feels like suicide!
    [self release];
}

@end
