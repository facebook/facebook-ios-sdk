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

#import "FBGraphObjectTableSelection.h"
#import "FBUtility.h"

@interface FBGraphObjectTableSelection() <UITableViewDelegate, FBGraphObjectSelectionQueryDelegate> 

@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) NSArray *selection;

- (void)selectItem:(FBGraphObject *)item
              cell:(UITableViewCell *)cell;
- (void)deselectItem:(FBGraphObject *)item
                cell:(UITableViewCell *)cell;
- (void)selectionChanged;

@end

@implementation FBGraphObjectTableSelection

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize selection = _selection;

- (id)initWithDataSource:(FBGraphObjectTableDataSource *)dataSource
{
    self = [super init];
    
    if (self) {
        dataSource.selectionDelegate = self;

        self.dataSource = dataSource;

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

- (void)deselectItem:(FBGraphObject *)item
                cell:(UITableViewCell *)cell
{
    id<FBGraphObject> selectedItem = [FBUtility graphObjectInArray:self.selection withSameIDAs:item];
    if (selectedItem) {
        NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
        [selection removeObject:selectedItem];
        self.selection = selection;
        [selection release];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    [self selectionChanged];
}

- (void)selectionChanged
{
    if ([self.delegate respondsToSelector:
         @selector(graphObjectTableSelectionDidChange:)]) {
        [self.delegate graphObjectTableSelectionDidChange:self];
    }
}

#pragma mark - FBGraphObjectSelectionDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
             selectionIncludesItem:(id<FBGraphObject>)item
{
    return [FBUtility graphObjectInArray:self.selection withSameIDAs:item] != nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        FBGraphObject *item = [self.dataSource itemAtIndexPath:indexPath];
        if (cell.accessoryType == UITableViewCellAccessoryNone) {
            [self selectItem:item cell:cell];
        } else {
            [self deselectItem:item cell:cell];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        FBGraphObject *item = [self.dataSource itemAtIndexPath:indexPath];
        [self deselectItem:item cell:cell];
    }
}

@end
