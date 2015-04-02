// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "Utilities.h"

const CGFloat DragOffsetY = 20.0;
const CGFloat FadeAnimationDuration = 0.3;
const CGFloat HighlightScale = 1.4;
const CGFloat MoveAnimationDuration = 0.4;
const NSUInteger NumberOfTiles = 9;

#define REL_BOARD_SIZE 400.0
#define REL_BOARD_PADDING 1.0
#define REL_GROUP_PADDING 3.0
#define REL_TILE_MARGIN 6.0
#define REL_TILE_SIZE 37.0

void AddDropShadow(UIView *view, CGFloat scale)
{
  view.layer.masksToBounds = NO;
  view.layer.shadowColor = [UIColor blackColor].CGColor;
  view.layer.shadowOffset = CGSizeMake(scale, scale * 2);
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowRadius = scale;
}

static CGFloat screen_ceilf(CGFloat value)
{
  CGFloat scale = [UIScreen mainScreen].scale;
  return ceilf((value * scale)) / scale;
}

static CGFloat screen_floorf(CGFloat value)
{
  CGFloat scale = [UIScreen mainScreen].scale;
  return floorf((value * scale)) / scale;
}

static CGFloat GetTileScale(CGFloat containerLength)
{
  return containerLength / REL_BOARD_SIZE;
}

CGFloat GetTileCenter(CGFloat containerLength, NSUInteger position)
{
  CGFloat scale = GetTileScale(containerLength);
  CGFloat center = (REL_BOARD_PADDING +
                    ((position + 1) * REL_TILE_MARGIN) +
                    (position * REL_TILE_SIZE) +
                    ((position / 3) * REL_GROUP_PADDING) +
                    (REL_TILE_SIZE / 2));
  return screen_floorf(scale * center);
}

CGFloat GetTilePadding(CGFloat containerLength)
{
  CGFloat scale = GetTileScale(containerLength);
  return screen_floorf(scale * (REL_BOARD_PADDING + REL_TILE_MARGIN));
}

CGSize GetTileSize(CGFloat containerLength)
{
  CGFloat scale = GetTileScale(containerLength);
  CGFloat size = screen_ceilf(scale * REL_TILE_SIZE);
  return CGSizeMake(size, size);
}

static NSMutableArray *seedGrid()
{
  NSString *string = @"123456789456789123789123456234567891567891234891234567345678912678912345912345678";
  NSMutableArray *grid = [[NSMutableArray alloc] init];
  NSUInteger count = [string length];
  for (NSUInteger i = 0; i < count; ++i) {
    [grid addObject:@([[string substringWithRange:NSMakeRange(i, 1)] integerValue])];
  }
  return grid;
}

static NSUInteger GridRandomOther(NSUInteger value, NSUInteger count)
{
  return ((value % count) + ((arc4random() % (count - 1)) + 1)) % count;
}

static void GridShuffleRow(NSMutableArray *grid)
{
  NSUInteger row1 = arc4random() % 9;
  NSUInteger row2 = ((row1 / 3) * 3) + GridRandomOther(row1, 3);
  NSRange row1Range = NSMakeRange(row1 * 9, 9);
  NSRange row2Range = NSMakeRange(row2 * 9, 9);
  NSArray *row1Values = [grid subarrayWithRange:row1Range];
  [grid replaceObjectsInRange:row1Range withObjectsFromArray:grid range:row2Range];
  [grid replaceObjectsInRange:row2Range withObjectsFromArray:row1Values range:NSMakeRange(0, 9)];
}

static void GridShuffleRowGroup(NSMutableArray *grid)
{
  NSUInteger rowGroup1 = arc4random() % 3;
  NSUInteger rowGroup2 = GridRandomOther(rowGroup1, 3);
  NSRange rowGroup1Range = NSMakeRange(rowGroup1 * 3 * 9, 3 * 9);
  NSRange rowGroup2Range = NSMakeRange(rowGroup2 * 3 * 9, 3 * 9);
  NSArray *rowGroup1Values = [grid subarrayWithRange:rowGroup1Range];
  [grid replaceObjectsInRange:rowGroup1Range withObjectsFromArray:grid range:rowGroup2Range];
  [grid replaceObjectsInRange:rowGroup2Range withObjectsFromArray:rowGroup1Values range:NSMakeRange(0, 3 * 9)];
}

static void GridShuffleColumn(NSMutableArray *grid)
{
  NSUInteger col1 = arc4random() % 9;
  NSUInteger col2 = ((col1 / 3) * 3) + GridRandomOther(col1, 3);
  NSMutableIndexSet *col1Indexes = [[NSMutableIndexSet alloc] init];
  NSMutableIndexSet *col2Indexes = [[NSMutableIndexSet alloc] init];
  for (NSUInteger i = 0; i < 9; ++i) {
    [col1Indexes addIndex:(i * 9) + col1];
    [col2Indexes addIndex:(i * 9) + col2];
  }
  NSArray *col1Values = [grid objectsAtIndexes:col1Indexes];
  NSArray *col2Values = [grid objectsAtIndexes:col2Indexes];
  [grid replaceObjectsAtIndexes:col1Indexes withObjects:col2Values];
  [grid replaceObjectsAtIndexes:col2Indexes withObjects:col1Values];
}

static void GridShuffleColumnGroup(NSMutableArray *grid)
{
  NSUInteger colGroup1 = arc4random() % 3;
  NSUInteger colGroup2 = GridRandomOther(colGroup1, 3);
  NSMutableIndexSet *colGroup1Indexes = [[NSMutableIndexSet alloc] init];
  NSMutableIndexSet *colGroup2Indexes = [[NSMutableIndexSet alloc] init];
  for (NSUInteger i = 0; i < 9; ++i) {
    for (NSUInteger j = 0; j < 3; ++j) {
      [colGroup1Indexes addIndex:(i * 9) + (colGroup1 * 3) + j];
      [colGroup2Indexes addIndex:(i * 9) + (colGroup2 * 3) + j];
    }
  }
  NSArray *colGroup1Values = [grid objectsAtIndexes:colGroup1Indexes];
  NSArray *colGroup2Values = [grid objectsAtIndexes:colGroup2Indexes];
  [grid replaceObjectsAtIndexes:colGroup1Indexes withObjects:colGroup2Values];
  [grid replaceObjectsAtIndexes:colGroup2Indexes withObjects:colGroup1Values];
}

static void GridTranspose(NSMutableArray *grid)
{
  for (NSUInteger row = 0; row < 9; ++row) {
    for (NSUInteger col = row + 1; col < 9; ++col) {
      NSUInteger index1 = (row * 9) + col;
      NSUInteger index2 = (col * 9) + row;
      [grid exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    }
  }
}

static void GridShuffle(NSMutableArray *grid)
{
  switch (arc4random() % 5) {
    case 0:{
      GridShuffleRow(grid);
      break;
    }
    case 1:{
      GridShuffleRowGroup(grid);
      break;
    }
    case 2:{
      GridShuffleColumn(grid);
      break;
    }
    case 3:{
      GridShuffleColumnGroup(grid);
      break;
    }
    case 4:{
      GridTranspose(grid);
      break;
    }
  }
}

static void GridRemoveValue(NSMutableArray *grid, NSMutableArray *remainingPositions)
{
  NSUInteger index = arc4random() % [remainingPositions count];
  NSUInteger position = [[remainingPositions objectAtIndex:index] unsignedIntegerValue];
  [remainingPositions removeObjectAtIndex:index];
  grid[position] = @0;
}

NSArray *GenerateGridValues(NSUInteger numberOfOpenValues)
{
  NSMutableArray *grid = seedGrid();
  for (NSUInteger i = 0; i < 9; ++i) {
    GridShuffle(grid);
  }
  NSMutableArray *remainingPositions = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < 9 * 9; ++i) {
    remainingPositions[i] = @(i);
  }
  for (NSUInteger i = 0; i < numberOfOpenValues; ++i) {
    GridRemoveValue(grid, remainingPositions);
  }
  return grid;
}

static BOOL ValidateGridValueAtPosition(NSArray *grid,
                                        NSUInteger positionToValidate,
                                        NSUInteger value,
                                        NSUInteger position)
{
  if (value == 0) {
    return YES;
  }
  if (positionToValidate == position) {
    return YES;
  }
  return ([grid[positionToValidate] unsignedIntegerValue] != value);
}

static BOOL ValidateGridValueInRow(NSArray *grid, NSUInteger row, NSUInteger value, NSUInteger position)
{
  for (NSUInteger i = 0; i < 9; ++i) {
    if (!ValidateGridValueAtPosition(grid, (row * 9) + i, value, position)) {
      return NO;
    }
  }
  return YES;
}

static BOOL ValidateGridValueInColumn(NSArray *grid, NSUInteger column, NSUInteger value, NSUInteger position)
{
  for (NSUInteger i = 0; i < 9; ++i) {
    if (!ValidateGridValueAtPosition(grid, (i * 9) + column, value, position)) {
      return NO;
    }
  }
  return YES;
}

static BOOL ValidateGridValueInGroup(NSArray *grid, NSUInteger group, NSUInteger value, NSUInteger position)
{
  NSUInteger startRow = (group / 3) * 3;
  NSUInteger startCol = (group % 3) * 3;
  for (NSUInteger row = startRow; row < startRow + 3; ++row) {
    for (NSUInteger col = startCol; col < startCol + 3; ++col) {
      if (!ValidateGridValueAtPosition(grid, (row * 9) + col, value, position)) {
        return NO;
      }
    }
  }
  return YES;
}

BOOL ValidateGridValue(NSArray *grid, NSUInteger position)
{
  NSUInteger row = position / 9;
  NSUInteger col = position % 9;

  NSUInteger group = ((row / 3) * 3) + (col / 3);
  NSUInteger value = [grid[position] unsignedIntegerValue];
  return (ValidateGridValueInRow(grid, row, value, position) &&
          ValidateGridValueInColumn(grid, col, value, position) &&
          ValidateGridValueInGroup(grid, group, value, position));
}
