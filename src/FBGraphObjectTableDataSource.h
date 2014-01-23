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

#import <UIKit/UIKit.h>

#import "FBGraphObject.h"

@protocol FBGraphObjectViewControllerDelegate;
@protocol FBGraphObjectSelectionQueryDelegate;
@protocol FBGraphObjectDataSourceDataNeededDelegate;
@class FBGraphObjectTableCell;

@interface FBGraphObjectTableDataSource : NSObject<UITableViewDataSource>

@property (nonatomic, retain) UIImage *defaultPicture;
@property (nonatomic, assign) id<FBGraphObjectViewControllerDelegate> controllerDelegate;
@property (nonatomic, copy) NSString *groupByField;
@property (nonatomic, assign) BOOL useCollation;
@property (nonatomic) BOOL itemTitleSuffixEnabled;
@property (nonatomic) BOOL itemPicturesEnabled;
@property (nonatomic) BOOL itemSubtitleEnabled;
@property (nonatomic, assign) id<FBGraphObjectSelectionQueryDelegate> selectionDelegate;
@property (nonatomic, assign) id<FBGraphObjectDataSourceDataNeededDelegate> dataNeededDelegate;
@property (nonatomic, copy) NSArray *sortDescriptors;

- (NSString *)fieldsForRequestIncluding:(NSSet *)customFields, ...;

- (void)setSortingBySingleField:(NSString*)fieldName ascending:(BOOL)ascending;
- (void)setSortingByFields:(NSArray*)fieldNames ascending:(BOOL)ascending;

- (void)prepareForNewRequest;
// Clears all graph objects from the data source.
- (void)clearGraphObjects;
// Adds additional graph objects (pass nil to indicate all objects have been added).
- (void)appendGraphObjects:(NSArray *)data;
- (BOOL)hasGraphObjects;

- (void)bindTableView:(UITableView *)tableView;

- (void)cancelPendingRequests;

// Call this when updating any property or if
// delegate.filterIncludesItem would return a different answer now.
- (void)update;

// Returns the graph object at a given indexPath.
- (FBGraphObject *)itemAtIndexPath:(NSIndexPath *)indexPath;

// Returns the indexPath for a given graph object.
- (NSIndexPath *)indexPathForItem:(FBGraphObject *)item;

@end

@protocol FBGraphObjectViewControllerDelegate <NSObject>
@required

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                             titleOfItem:(id<FBGraphObject>)graphObject;

@optional

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                       titleSuffixOfItem:(id<FBGraphObject>)graphObject;

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                          subtitleOfItem:(id<FBGraphObject>)graphObject;

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                        pictureUrlOfItem:(id<FBGraphObject>)graphObject;

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                filterIncludesItem:(id<FBGraphObject>)item;

- (void)graphObjectTableDataSource:(FBGraphObjectTableDataSource*)dataSource
                customizeTableCell:(FBGraphObjectTableCell*)cell;

@end

@protocol FBGraphObjectSelectionQueryDelegate <NSObject>

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
             selectionIncludesItem:(id<FBGraphObject>)item;

@end

@protocol FBGraphObjectDataSourceDataNeededDelegate <NSObject>

- (void)graphObjectTableDataSourceNeedsData:(FBGraphObjectTableDataSource *)dataSource triggeredByIndexPath:(NSIndexPath*)indexPath;

@end
