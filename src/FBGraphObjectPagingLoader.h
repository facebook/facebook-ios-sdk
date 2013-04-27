/*
 * Copyright 2010-present Facebook.
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

#import <Foundation/Foundation.h>
#import "FBGraphObjectTableDataSource.h"

@class FBSession;
@class FBRequest;
@protocol FBGraphObjectPagingLoaderDelegate;

typedef enum {
    // Paging links will be followed as soon as one set of results is loaded
    FBGraphObjectPagingModeImmediate,
    // Paging links will be followed as soon as one set of results is loaded, even without a view
    FBGraphObjectPagingModeImmediateViewless,
    // Paging links will be followed only when the user scrolls to the bottom of the table
    FBGraphObjectPagingModeAsNeeded
} FBGraphObjectPagingMode;

@interface FBGraphObjectPagingLoader : NSObject<FBGraphObjectDataSourceDataNeededDelegate>

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBSession *session;
@property (nonatomic, assign) id<FBGraphObjectPagingLoaderDelegate> delegate;
@property (nonatomic, readonly) FBGraphObjectPagingMode pagingMode;
@property (nonatomic, readonly) BOOL isResultFromCache;
 
- (id)initWithDataSource:(FBGraphObjectTableDataSource*)aDataSource
              pagingMode:(FBGraphObjectPagingMode)pagingMode;
- (void)startLoadingWithRequest:(FBRequest*)request
                  cacheIdentity:(NSString*)cacheIdentity 
          skipRoundtripIfCached:(BOOL)skipRoundtripIfCached;
- (void)addResultsAndUpdateView:(NSDictionary*)results;
- (void)cancel;
- (void)reset;

@end

@protocol FBGraphObjectPagingLoaderDelegate <NSObject>

@optional

- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader willLoadURL:(NSString*)url;
- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader didLoadData:(NSDictionary*)results;
- (void)pagingLoaderDidFinishLoading:(FBGraphObjectPagingLoader*)pagingLoader;
- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader handleError:(NSError*)error;
- (void)pagingLoaderWasCancelled:(FBGraphObjectPagingLoader*)pagingLoader;

@end
