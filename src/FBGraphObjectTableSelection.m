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

#import "FBGraphObjectTableSelection.h"
#import "FBUtility.h"

@interface FBGraphObjectTableSelection() <UITableViewDelegate, FBGraphObjectSelectionQueryDelegate> 

@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) NSArray *selection;

- (void)selectItem:(FBGraphObject *)item
              cell:(UITableViewCell *)cell;

- (void)    deselectItem:(FBGraphObject *)item
                    cell:(UITableViewCell *)cell
   raiseSelectionChanged:(BOOL) raiseSelectionChanged;

- (void)selectionChanged;

@end

@implementation FBGraphObjectTableSelection

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize selection = _selection;
@synthesize allowsMultipleSelection = _allowMultipleSelection;

- (id)initWithDataSource:(FBGraphObjectTableDataSource *)dataSource
{
    self = [super init];
    
    if (self) {
        dataSource.selectionDelegate = self;

        self.dataSource = dataSource;
        self.allowsMultipleSelection = YES;
        
        NSArray *selection = [[NSArray alloc] init];
        self.selection = selection;
        [selection release];
    }
    
    return self;
}

- (void)dealloc
{
    _dataSource.selectionDelegate = nil;
    
    [_dataSource release];
    [_selection release];

    [super dealloc];
}

- (void)clearSelectionInTableView:(UITableView*)tableView {
    if (self.selection.count > 0) {
        [self deselectItems:self.selection tableView:tableView];
        [self selectionChanged];
    }
}

- (void)selectItem:(FBGraphObject *)item
              cell:(UITableViewCell *)cell
{
    if ([FBUtility graphObjectInArray:self.selection withSameIDAs:item] == nil) {
        NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
        [selection addObject:item];
        self.selection = selection;
        [selection release];
    }
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self selectionChanged];
}

- (void)    deselectItem:(FBGraphObject *)item
                    cell:(UITableViewCell *)cell
   raiseSelectionChanged:(BOOL) raiseSelectionChanged
{
    id<FBGraphObject> selectedItem = [FBUtility graphObjectInArray:self.selection withSameIDAs:item];
    if (selectedItem) {
        NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
        [selection removeObject:selectedItem];
        self.selection = selection;
        [selection release];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (raiseSelectionChanged) {
        [self selectionChanged];
    }
}

// Note this method does NOT automatically "raise" the selectionChanged event.
- (void)deselectItems:(NSArray*)items tableView:(UITableView*)tableView
{
    // Copy this so it doesn't change from under us.
    items = [NSArray arrayWithArray:items];
    
    for (FBGraphObject *item in items) {
        NSIndexPath *indexPath = [self.dataSource indexPathForItem:item];
        
        UITableViewCell *cell = nil;
        if (indexPath != nil) {
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
        
        [self deselectItem:item cell:cell raiseSelectionChanged:NO];
    }
}

- (void)selectionChanged
{
    if ([self.delegate respondsToSelector:
         @selector(graphObjectTableSelectionDidChange:)]) {
        // Let the table view finish updating its UI before notifying the delegate.
        [self.delegate performSelector:@selector(graphObjectTableSelectionDidChange:) withObject:self afterDelay:.1];
    }
}

- (BOOL)selectionIncludesItem:(id<FBGraphObject>)item
{
    return [FBUtility graphObjectInArray:self.selection withSameIDAs:item] != nil;
}

#pragma mark - FBGraphObjectSelectionDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
             selectionIncludesItem:(id<FBGraphObject>)item
{
    return [self selectionIncludesItem:item];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // cell may be nil, which is okay, it will pick up the right selected state when it is created.
   
    FBGraphObject *item = [self.dataSource itemAtIndexPath:indexPath];
    if (item != nil) {
        // We want to support multi-select on iOS <5.0, so rather than rely on the table view's notion
        // of selection, just treat this as a toggle. If it is already selected, deselect it, and vice versa.
        if (![self selectionIncludesItem:item]) {
            if (self.allowsMultipleSelection == NO) {
                // No multi-select allowed, deselect what is already selected.
                [self deselectItems:self.selection tableView:tableView];
            }
            [self selectItem:item cell:cell];
        } else {
            [self deselectItem:item cell:cell raiseSelectionChanged:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.allowsMultipleSelection == NO) {
        // Only deselect if we are not allowing multi select. Otherwise, the user will manually
        // deselect this item by clicking on it again.
        
        // cell may be nil, which is okay, it will pick up the right selected state when it is created.
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
 
        FBGraphObject *item = [self.dataSource itemAtIndexPath:indexPath];
        [self deselectItem:item cell:cell raiseSelectionChanged:NO];
    }
}

#pragma mark Debugging helpers

- (NSString*)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, allowsMultipleSelection: %@, delegate: %p, selection: [",
                               NSStringFromClass([self class]), 
                               self,
                               self.allowsMultipleSelection ? @"YES" : @"NO",
                               self.delegate];
                               
    bool firstItem = YES;
    for (FBGraphObject *item in self.selection) {
        id objectId = [item objectForKey:@"id"];
        if (!firstItem) {
            [result appendFormat:@", "];
        }
        firstItem = NO;
        [result appendFormat:@"%@", (objectId != nil) ? objectId : @"<FBGraphObject>"];
    }
    [result appendFormat:@"]>"];
    
    return result;
    
}


#pragma mark -

@end
