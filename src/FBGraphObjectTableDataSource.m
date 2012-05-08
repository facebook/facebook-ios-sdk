/*
 * Copyright 2012 Facebook
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

#import "FBGraphObjectTableDataSource.h"
#import "FBSubtitledTableViewCell.h"
#import "FBGraphObject.h"
#import "FBURLConnection.h"

@interface FBGraphObjectTableDataSource () {
    NSArray *_data;
    UIImage *_defaultPicture;
    NSString *_displayPicturePropertyName;
    NSString *_displayPrimaryPropertyName;
    NSString *_displaySecondaryPropertyName;
    id<FBGraphObjectFilterDelegate> _filterDelegate;
    NSString *_groupByPropertyName;
    NSArray *_indexKeys;
    NSDictionary *_indexMap;
    NSMutableSet *_pendingURLConnections;
    id<FBGraphObjectSelectionQueryDelegate> _selectionDelegate;
}

@property (nonatomic, retain) NSArray *indexKeys;
@property (nonatomic, retain) NSDictionary *indexMap;
@property (nonatomic, retain) NSMutableSet *pendingURLConnections;

- (BOOL)filterIncludesItem:(FBGraphObject *)item;
- (NSArray *)ensureSortDescriptors;
- (BOOL)hasSubtitle;
- (UITableViewCell *)cellWithTableView:(UITableView *)tableView;
- (NSString *)indexKeyOfItem:(FBGraphObject *)item;
- (NSIndexPath *)indexPathForItem:(FBGraphObject *)item;
- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item;
- (void)addOrRemovePendingConnection:(FBURLConnection *)connection;

@end

@implementation FBGraphObjectTableDataSource

@synthesize data = _data;
@synthesize defaultPicture = _defaultPicture;
@synthesize displayPicturePropertyName = _displayPicturePropertyName;
@synthesize displayPrimaryPropertyName = _displayPrimaryPropertyName;
@synthesize displaySecondaryPropertyName = _displaySecondaryPropertyName;
@synthesize filterDelegate = _filterDelegate;
@synthesize groupByPropertyName = _groupByPropertyName;
@synthesize indexKeys = _indexKeys;
@synthesize indexMap = _indexMap;
@synthesize pendingURLConnections = _pendingURLConnections;
@synthesize selectionDelegate = _selectionDelegate;
@synthesize sortDescriptors = _sortDescriptors;

- (id)init
{
    self = [super init];
    
    if (self) {
        self.displayPrimaryPropertyName = @"name";
        self.displayPicturePropertyName = @"picture";
        self.groupByPropertyName = @"name";

        NSMutableSet *pendingURLConnections = [[NSMutableSet alloc] init];
        self.pendingURLConnections = pendingURLConnections;
        [pendingURLConnections release];
    }
    
    return self;
}

- (void)dealloc
{
    NSAssert(![_pendingURLConnections count],
             @"FBGraphObjectTableDataSource pending connection did not retain self");

    [_data release];
    [_defaultPicture release];
    [_displayPicturePropertyName release];
    [_displayPrimaryPropertyName release];
    [_displaySecondaryPropertyName release];
    [_groupByPropertyName release];
    [_indexKeys release];
    [_indexMap release];
    [_pendingURLConnections release];
    [_sortDescriptors release];

    [super dealloc];
}

#pragma mark - Public Methods

- (void)addRequestPropertyNamesToSet:(NSMutableSet *)properties
{
    if (self.displayPrimaryPropertyName) {
        [properties addObject:self.displayPrimaryPropertyName];
    }
    if (self.displaySecondaryPropertyName) {
        [properties addObject:self.displaySecondaryPropertyName];
    }
    if (self.displayPicturePropertyName) {
        [properties addObject:self.displayPicturePropertyName];
    }
    if (self.groupByPropertyName) {
        [properties addObject:self.groupByPropertyName];
    }
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
    }
    
    NSArray *sortDescriptors = [self ensureSortDescriptors];
    for (NSString *key in indexKeys) {
        [[indexMap objectForKey:key]
         sortUsingDescriptors:sortDescriptors];
    }
    [indexKeys sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    self.indexKeys = indexKeys;
    self.indexMap = indexMap;
}

#pragma mark - Private Methods

- (BOOL)filterIncludesItem:(FBGraphObject *)item
{
    if (![self.filterDelegate respondsToSelector:
          @selector(graphObjectTableDataSource:filterIncludesItem:)]) {
        return YES;
    }

    return [self.filterDelegate graphObjectTableDataSource:self
                                        filterIncludesItem:item];
}

- (NSArray *)ensureSortDescriptors
{
    if (!self.sortDescriptors) {
        NSSortDescriptor *sortBy = [NSSortDescriptor
                                    sortDescriptorWithKey:@"name"
                                    ascending:YES
                                    selector:@selector(localizedCaseInsensitiveCompare:)];
        self.sortDescriptors = [NSArray arrayWithObjects:sortBy, nil];
    }
    
    return self.sortDescriptors;
}

- (BOOL)hasSubtitle
{
    return self.displaySecondaryPropertyName != nil;
}

- (UITableViewCell *)cellWithTableView:(UITableView *)tableView
{
    static NSString *titleOnlyCellKey = @"fbCellTitleOnly";
    static NSString *titleAndSubtitleCellKey = @"fbCellTitleAndSubtitle";
    NSString *cellKey = [self hasSubtitle] ? titleAndSubtitleCellKey : titleOnlyCellKey;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellKey];
    if (!cell) {
        if ([self hasSubtitle]) {
            cell = [[FBSubtitledTableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:titleAndSubtitleCellKey];
        } else {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:titleOnlyCellKey];
        }
        [cell autorelease];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (NSString *)indexKeyOfItem:(FBGraphObject *)item
{
    NSString *text = @"";
    
    if (self.groupByPropertyName) {
        text = [item objectForKey:self.groupByPropertyName];
    }
    
    if ([text length] > 1) {
        text = [text substringToIndex:1];
    }
    
    text = [text uppercaseString];
    
    return text;
}

- (FBGraphObject *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    id key = [self.indexKeys objectAtIndex:indexPath.section];
    NSArray *sectionItems = [self.indexMap objectForKey:key];
    return [sectionItems objectAtIndex:indexPath.row];
}

- (NSIndexPath *)indexPathForItem:(FBGraphObject *)item
{
    NSString *key = [self indexKeyOfItem:item];
    NSMutableArray *sectionItems = [self.indexMap objectForKey:key];
    if (!sectionItems) {
        return nil;
    }
    
    NSInteger sectionIndex = [self.indexKeys indexOfObject:key];
    if (sectionIndex == NSNotFound) {
        return nil;
    }
    
    NSInteger itemIndex = [sectionItems indexOfObjectIdenticalTo:item];
    if (itemIndex == NSNotFound) {
        return nil;
    }
    
    return [NSIndexPath indexPathForRow:itemIndex inSection:sectionIndex];
}

- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item
{
    __block UIImage *image = nil;
    NSString *urlString = [item objectForKey:self.displayPicturePropertyName];
    if (urlString) {
        FBURLConnectionHandler handler =
        ^(FBURLConnection *connection, NSError *error, NSURLResponse *response, NSData *data) {
            [self addOrRemovePendingConnection:connection];
            if (!error) {
                image = [UIImage imageWithData:data];

                NSIndexPath *indexPath = [self indexPathForItem:item];
                if (indexPath) {
                    UITableViewCell *cell = [tableView
                                             cellForRowAtIndexPath:indexPath];
                    if (cell) {
                        cell.imageView.image = image;
                        [cell setNeedsLayout];
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
    return [self.indexKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    id key = [self.indexKeys objectAtIndex:section];
    NSArray *sectionItems = [self.indexMap objectForKey:key];
    return [sectionItems count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.indexKeys;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellWithTableView:tableView];
    FBGraphObject *item = [self itemAtIndexPath:indexPath];
    
    NSString *primary = [item objectForKey:self.displayPrimaryPropertyName];
    if ([self hasSubtitle]) {
        NSString *secondary = [item objectForKey:self.displaySecondaryPropertyName];
        ((FBSubtitledTableViewCell *)cell).subtitle = secondary;
        ((FBSubtitledTableViewCell *)cell).title = primary;
    } else {
        cell.textLabel.text = primary;
    }
    
    if (self.displayPicturePropertyName) {
        cell.imageView.image = [self tableView:tableView imageForItem:item];
    } else {
        cell.imageView.image = nil;
    }
    
    if ([self.selectionDelegate graphObjectTableDataSource:self
                                     selectionIncludesItem:item]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

@end
