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

#import "FBGraphObjectTableDataSource.h"

#import "FBGraphObject.h"
#import "FBGraphObjectTableCell.h"
#import "FBURLConnection.h"
#import "FBUtility.h"

// Magic number - iPhone address book doesn't show scrubber for less than 5 contacts
static const NSInteger kMinimumCountToCollate = 6;

@interface FBGraphObjectTableDataSource ()

@property (nonatomic, retain) NSArray *data;
@property (nonatomic, retain) NSArray *indexKeys;
@property (nonatomic, retain) NSDictionary *indexMap;
@property (nonatomic, retain) NSMutableSet *pendingURLConnections;
@property (nonatomic, assign) BOOL expectingMoreGraphObjects;
@property (nonatomic, retain) UILocalizedIndexedCollation *collation;
@property (nonatomic, assign) BOOL showSections;

- (BOOL)filterIncludesItem:(FBGraphObject *)item;
- (FBGraphObjectTableCell *)cellWithTableView:(UITableView *)tableView;
- (NSString *)indexKeyOfItem:(FBGraphObject *)item;
- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item;
- (void)addOrRemovePendingConnection:(FBURLConnection *)connection;
- (BOOL)isActivityIndicatorIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isLastSection:(NSInteger)section;

@end

@implementation FBGraphObjectTableDataSource

- (void)setUseCollation:(BOOL)useCollation
{
    if (_useCollation != useCollation) {
        _useCollation = useCollation;
        self.collation = _useCollation ? [UILocalizedIndexedCollation currentCollation] : nil;
    }
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        NSMutableSet *pendingURLConnections = [[NSMutableSet alloc] init];
        self.pendingURLConnections = pendingURLConnections;
        [pendingURLConnections release];
        self.expectingMoreGraphObjects = YES;
    }

    return self;
}

- (void)dealloc
{
    FBConditionalLog(![_pendingURLConnections count],
                     @"FBGraphObjectTableDataSource pending connection did not retain self");

    [_collation release];
    [_data release];
    [_defaultPicture release];
    [_groupByField release];
    [_indexKeys release];
    [_indexMap release];
    [_pendingURLConnections release];
    [_sortDescriptors release];

    [super dealloc];
}

#pragma mark - Public Methods

- (NSString *)fieldsForRequestIncluding:(NSSet *)customFields, ...
{
    // Start with custom fields.
    NSMutableSet *nameSet = [[NSMutableSet alloc] initWithSet:customFields];

    // Iterate through varargs after the initial set, and add them
    id vaName;
    va_list vaArguments;
    va_start(vaArguments, customFields);
    while ((vaName = va_arg(vaArguments, id))) {
        [nameSet addObject:vaName];
    }
    va_end(vaArguments);

    // Add fields needed for data source functionality.
    if (self.groupByField) {
        [nameSet addObject:self.groupByField];
    }

    // get a stable order for our fields, because we use the resulting URL as a cache ID
    NSMutableArray *sortedFields = [[nameSet allObjects] mutableCopy];
    [sortedFields sortUsingSelector:@selector(caseInsensitiveCompare:)];

    [nameSet release];

    // Build the comma-separated string
    NSMutableString *fields = [[[NSMutableString alloc] init] autorelease];

    for (NSString *field in sortedFields) {
        if ([fields length]) {
            [fields appendString:@","];
        }
        [fields appendString:field];
    }

    [sortedFields release];
    return fields;
}

- (void)prepareForNewRequest {
    self.data = nil;
    self.expectingMoreGraphObjects = YES;
}

- (void)clearGraphObjects {
    self.indexKeys = nil;
    self.indexMap = nil;
    [self prepareForNewRequest];
}

- (void)appendGraphObjects:(NSArray *)data
{
    if (self.data) {
        self.data = [self.data arrayByAddingObjectsFromArray:data];
    } else {
        self.data = data;
    }
    if (data == nil) {
        self.expectingMoreGraphObjects = NO;
    }
}

- (BOOL)hasGraphObjects {
    return self.data && self.data.count > 0;
}

- (void)bindTableView:(UITableView *)tableView
{
    tableView.dataSource = self;
    tableView.rowHeight = [FBGraphObjectTableCell rowHeight];
}

- (void)cancelPendingRequests
{
    // Cancel all active connections.
    for (FBURLConnection *connection in _pendingURLConnections) {
        [connection cancel];
    }
}

// Called after changing any properties.  To simplify the code here,
// since this class is internal, we do not auto-update on property
// changes.
//
// This builds indexMap and indexKeys, the data structures used to
// respond to UITableDataSource protocol requests.  UITable expects
// a list of section names, and then ask for items given a section
// index and item index within that section.  In addition, we need
// to do reverse mapping from item to table location.
//
// To facilitate both of these, we build an array of section titles,
// and a dictionary mapping title -> item array.  We could consider
// building a reverse-lookup map too, but this seems unnecessary.
- (void)update
{
    NSInteger objectsShown = 0;
    NSMutableDictionary *indexMap = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableArray *indexKeys = [[[NSMutableArray alloc] init] autorelease];

    for (FBGraphObject *item in self.data) {
        if (![self filterIncludesItem:item]) {
            continue;
        }

        NSString *key = [self indexKeyOfItem:item];
        NSMutableArray *existingSection = [indexMap objectForKey:key];
        NSMutableArray *section = existingSection;

        if (!section) {
            section = [[[NSMutableArray alloc] init] autorelease];
        }
        [section addObject:item];

        if (!existingSection) {
            [indexMap setValue:section forKey:key];
            [indexKeys addObject:key];
        }
        objectsShown++;
    }

    if (self.sortDescriptors) {
        for (NSString *key in indexKeys) {
            [[indexMap objectForKey:key] sortUsingDescriptors:self.sortDescriptors];
        }
    }
    if (!self.useCollation) {
        [indexKeys sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }

    self.showSections = objectsShown >= kMinimumCountToCollate;
    self.indexKeys = indexKeys;
    self.indexMap = indexMap;
}

#pragma mark - Private Methods

- (BOOL)filterIncludesItem:(FBGraphObject *)item
{
    if (![self.controllerDelegate respondsToSelector:
          @selector(graphObjectTableDataSource:filterIncludesItem:)]) {
        return YES;
    }

    return [self.controllerDelegate graphObjectTableDataSource:self
                                            filterIncludesItem:item];
}

- (void)setSortingByFields:(NSArray *)fieldNames ascending:(BOOL)ascending {
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:fieldNames.count];
    for (NSString *fieldName in fieldNames) {
        NSSortDescriptor *sortBy = [NSSortDescriptor
                                    sortDescriptorWithKey:fieldName
                                    ascending:ascending
                                    selector:@selector(localizedCaseInsensitiveCompare:)];
        [sortDescriptors addObject:sortBy];
    }
    self.sortDescriptors = sortDescriptors;
}

- (void)setSortingBySingleField:(NSString *)fieldName ascending:(BOOL)ascending {
    [self setSortingByFields:[NSArray arrayWithObject:fieldName] ascending:ascending];
}

- (FBGraphObjectTableCell *)cellWithTableView:(UITableView *)tableView
{
    static NSString *const cellKey = @"fbTableCell";
    FBGraphObjectTableCell *cell =
    (FBGraphObjectTableCell *)[tableView dequeueReusableCellWithIdentifier:cellKey];

    if (!cell) {
        cell = [[FBGraphObjectTableCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:cellKey];
        [cell autorelease];

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return cell;
}

- (NSString *)indexKeyOfItem:(FBGraphObject *)item
{
    NSString *text = @"";

    if (self.groupByField) {
        text = [item objectForKey:self.groupByField] ?: @"";
    }

    if (self.useCollation) {
        NSInteger collationSection = [self.collation sectionForObject:item collationStringSelector:NSSelectorFromString(self.groupByField)];
        text = [[self.collation sectionTitles] objectAtIndex:collationSection];
    } else {

        if ([text length] > 1) {
            text = [text substringToIndex:1];
        }

        text = [text uppercaseString];
    }
    return text;
}

- (FBGraphObject *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    id key = nil;
    if (self.useCollation) {
        NSString *sectionTitle = [self.collation.sectionTitles objectAtIndex:indexPath.section];
        key = sectionTitle;
    } else if (indexPath.section >= 0 && indexPath.section < self.indexKeys.count) {
        key = [self.indexKeys objectAtIndex:indexPath.section];
    }
    NSArray *sectionItems = [self.indexMap objectForKey:key];
    if (indexPath.row >= 0 && indexPath.row < sectionItems.count) {
        return [sectionItems objectAtIndex:indexPath.row];
    }
    return nil;
}

- (NSIndexPath *)indexPathForItem:(FBGraphObject *)item
{
    NSString *key = [self indexKeyOfItem:item];
    NSMutableArray *sectionItems = [self.indexMap objectForKey:key];
    if (!sectionItems) {
        return nil;
    }

    NSInteger sectionIndex = 0;
    if (self.useCollation) {
        sectionIndex = [self.collation.sectionTitles indexOfObject:key];
    } else {
        sectionIndex = [self.indexKeys indexOfObject:key];
    }
    if (sectionIndex == NSNotFound) {
        return nil;
    }

    id matchingObject = [FBUtility graphObjectInArray:sectionItems withSameIDAs:item];
    if (matchingObject == nil) {
        return nil;
    }

    NSInteger itemIndex = [sectionItems indexOfObject:matchingObject];
    if (itemIndex == NSNotFound) {
        return nil;
    }

    return [NSIndexPath indexPathForRow:itemIndex inSection:sectionIndex];
}

- (BOOL)isLastSection:(NSInteger)section {
    if (self.useCollation) {
        return section == self.collation.sectionTitles.count - 1;
    } else {
        return section == self.indexKeys.count - 1;
    }
}

- (BOOL)isActivityIndicatorIndexPath:(NSIndexPath *)indexPath {
    if ([self isLastSection:indexPath.section]) {
        NSArray *sectionItems = [self sectionItemsForSection:indexPath.section];

        if (indexPath.row == sectionItems.count) {
            // Last section has one more row that items if we are expecting more objects.
            return YES;
        }
    }
    return NO;
}


- (NSString *)titleForSection:(NSInteger)sectionIndex
{
    id key;
    if (self.useCollation) {
        NSString *sectionTitle = [self.collation.sectionTitles objectAtIndex:sectionIndex];
        key = sectionTitle;
    } else {
        key = [self.indexKeys objectAtIndex:sectionIndex];
    }
    return key;
}

- (NSArray *)sectionItemsForSection:(NSInteger)sectionIndex
{
    id key = [self titleForSection:sectionIndex];
    NSArray *sectionItems = [self.indexMap objectForKey:key];
    return sectionItems;
}
- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item
{
    __block UIImage *image = nil;
    NSString *urlString = [self.controllerDelegate graphObjectTableDataSource:self
                                                             pictureUrlOfItem:item];
    if (urlString) {
        FBURLConnectionHandler handler =
        ^(FBURLConnection *connection, NSError *error, NSURLResponse *response, NSData *data) {
            [self addOrRemovePendingConnection:connection];
            if (!error) {
                image = [UIImage imageWithData:data];

                NSIndexPath *indexPath = [self indexPathForItem:item];
                if (indexPath) {
                    FBGraphObjectTableCell *cell =
                    (FBGraphObjectTableCell *)[tableView cellForRowAtIndexPath:indexPath];

                    if (cell) {
                        cell.picture = image;
                    }
                }
            }
        };

        FBURLConnection *connection = [[[FBURLConnection alloc]
                                        initWithURL:[NSURL URLWithString:urlString]
                                        completionHandler:handler]
                                       autorelease];

        [self addOrRemovePendingConnection:connection];
    }

    // If the picture had not been fetched yet by this object, but is cached in the
    // URL cache, we can complete synchronously above.  In this case, we will not
    // find the cell in the table because we are in the process of creating it. We can
    // just return the object here.
    if (image) {
        return image;
    }

    return self.defaultPicture;
}

// In tableView:imageForItem:, there are two code-paths, and both always run.
// Whichever runs first adds the connection to the collection of pending requests,
// and whichever runs second removes it.  This allows us to track all requests
// for which one code-path has run and the other has not.
- (void)addOrRemovePendingConnection:(FBURLConnection *)connection
{
    if ([self.pendingURLConnections containsObject:connection]) {
        [self.pendingURLConnections removeObject:connection];
    } else {
        [self.pendingURLConnections addObject:connection];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.useCollation) {
        return self.collation.sectionTitles.count;
    } else {
        return [self.indexKeys count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionItems = [self sectionItemsForSection:section];

    NSUInteger count = [sectionItems count];
    // If we are expecting more objects to be loaded via paging, add 1 to the
    // row count for the last section.
    if (self.expectingMoreGraphObjects &&
        self.dataNeededDelegate &&
        [self isLastSection:section]) {
        ++count;
    }
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!self.showSections) {
        return nil;
    }

    NSArray *sectionItems = [self sectionItemsForSection:section];
    return sectionItems.count > 0 ? [self titleForSection:section] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (self.useCollation) {
        return [self.collation sectionForSectionIndexTitleAtIndex:index];
    } else {
        return index;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (!self.showSections) {
        return nil;
    }

    if (self.useCollation) {
        return self.collation.sectionIndexTitles;
    } else {
        return [self.indexKeys count] > 1 ? self.indexKeys : nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FBGraphObjectTableCell *cell = [self cellWithTableView:tableView];

    if ([self isActivityIndicatorIndexPath:indexPath]) {
        cell.picture = nil;
        cell.subtitle = nil;
        cell.title = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selected = NO;

        [cell startAnimatingActivityIndicator];

        [self.dataNeededDelegate graphObjectTableDataSourceNeedsData:self
                                                triggeredByIndexPath:indexPath];
    } else {
        FBGraphObject *item = [self itemAtIndexPath:indexPath];

        // This is a no-op if it doesn't have an activity indicator.
        [cell stopAnimatingActivityIndicator];
        if (item) {
            if (self.itemPicturesEnabled) {
                cell.picture = [self tableView:tableView imageForItem:item];
            } else {
                cell.picture = nil;
            }

            if (self.itemTitleSuffixEnabled) {
                cell.titleSuffix = [self.controllerDelegate graphObjectTableDataSource:self
                                                                     titleSuffixOfItem:item];
            } else {
                cell.titleSuffix = nil;
            }

            if (self.itemSubtitleEnabled) {
                cell.subtitle = [self.controllerDelegate graphObjectTableDataSource:self
                                                                     subtitleOfItem:item];
            } else {
                cell.subtitle = nil;
            }

            cell.title = [self.controllerDelegate graphObjectTableDataSource:self
                                                                 titleOfItem:item];

            if ([self.selectionDelegate graphObjectTableDataSource:self
                                             selectionIncludesItem:item]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.selected = YES;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selected = NO;
            }

            if ([self.controllerDelegate respondsToSelector:@selector(graphObjectTableDataSource:customizeTableCell:)]) {
                [self.controllerDelegate graphObjectTableDataSource:self
                                                 customizeTableCell:cell];
            }
        } else {
            cell.picture = nil;
            cell.subtitle = nil;
            cell.title = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selected = NO;
        }
    }

    return cell;
}

@end
