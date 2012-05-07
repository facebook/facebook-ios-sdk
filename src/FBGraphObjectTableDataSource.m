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
    id<FBGraphObjectViewControllerDelegate> _controllerDelegate;
    NSString *_groupByField;
    NSArray *_indexKeys;
    NSDictionary *_indexMap;
    BOOL _itemPicturesEnabled;
    BOOL _itemSubtitleEnabled;
    NSMutableSet *_pendingURLConnections;
    id<FBGraphObjectSelectionQueryDelegate> _selectionDelegate;
    NSArray *_sortDescriptors;
}

@property (nonatomic, retain) NSArray *data;
@property (nonatomic, retain) NSArray *indexKeys;
@property (nonatomic, retain) NSDictionary *indexMap;
@property (nonatomic, retain) NSMutableSet *pendingURLConnections;

- (BOOL)filterIncludesItem:(FBGraphObject *)item;
- (NSArray *)ensureSortDescriptors;
- (UITableViewCell *)cellWithTableView:(UITableView *)tableView;
- (NSString *)indexKeyOfItem:(FBGraphObject *)item;
- (NSIndexPath *)indexPathForItem:(FBGraphObject *)item;
- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item;
- (void)addOrRemovePendingConnection:(FBURLConnection *)connection;

@end

@implementation FBGraphObjectTableDataSource

@synthesize data = _data;
@synthesize defaultPicture = _defaultPicture;
@synthesize controllerDelegate = _controllerDelegate;
@synthesize groupByField = _groupByField;
@synthesize indexKeys = _indexKeys;
@synthesize indexMap = _indexMap;
@synthesize itemPicturesEnabled = _itemPicturesEnabled;
@synthesize itemSubtitleEnabled = _itemSubtitleEnabled;
@synthesize pendingURLConnections = _pendingURLConnections;
@synthesize selectionDelegate = _selectionDelegate;
@synthesize sortDescriptors = _sortDescriptors;

- (id)init
{
    self = [super init];
    
    if (self) {
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

    // Build the comma-separated string
    NSMutableString *fields = [[[NSMutableString alloc] init] autorelease];

    for (NSString *field in nameSet) {
        if ([fields length]) {
            [fields appendString:@","];
        }
        [fields appendString:field];
    }

    [nameSet release];

    return fields;
}

- (void)setViewData:(NSArray *)data
{
    self.data = data;
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
    if (![self.controllerDelegate respondsToSelector:
          @selector(graphObjectTableDataSource:filterIncludesItem:)]) {
        return YES;
    }

    return [self.controllerDelegate graphObjectTableDataSource:self
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

- (UITableViewCell *)cellWithTableView:(UITableView *)tableView
{
    static NSString *titleOnlyCellKey = @"fbCellTitleOnly";
    static NSString *titleAndSubtitleCellKey = @"fbCellTitleAndSubtitle";
    NSString *cellKey = self.itemSubtitleEnabled ? titleAndSubtitleCellKey : titleOnlyCellKey;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellKey];
    if (!cell) {
        if (self.itemSubtitleEnabled) {
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
    
    if (self.groupByField) {
        text = [item objectForKey:self.groupByField];
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
    NSString *title = [self.controllerDelegate graphObjectTableDataSource:self
                                                              titleOfItem:item];
    if (self.itemSubtitleEnabled) {
        NSString *subtitle = [self.controllerDelegate graphObjectTableDataSource:self
                                                                  subtitleOfItem:item];
        ((FBSubtitledTableViewCell *)cell).subtitle = subtitle;
        ((FBSubtitledTableViewCell *)cell).title = title;
    } else {
        cell.textLabel.text = title;
    }

    if (self.itemPicturesEnabled) {
        cell.imageView.image = [self tableView:tableView imageForItem:item];
    } else {
        cell.imageView.image = nil;
    }
    
    if ([self.selectionDelegate graphObjectTableDataSource:self
                                     selectionIncludesItem:item]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.selected = YES;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selected = NO;
    }
    
    return cell;
}

@end
