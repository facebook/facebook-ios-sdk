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

#import "BoardView.h"

#import "Utilities.h"

@implementation BoardView
{
  NSArray *_targetViews;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self _configureBoardView];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if ((self = [super initWithCoder:decoder])) {
    [self _configureBoardView];
  }
  return self;
}

#pragma mark - Public Methods

- (BOOL)addTileView:(TileView *)tileView
{
  CGPoint locationInBoard = [self convertPoint:tileView.center fromView:tileView.superview];
  UIView *targetView = [self _emptyTargetViewAtLocation:locationInBoard];
  if (!targetView) {
    return NO;
  }
  CGPoint center = [targetView convertPoint:locationInBoard fromView:self];
  TileView *copy = [self _buildTileViewForTargetView:targetView value:tileView.value center:center];
  copy.transform = tileView.transform;
  [UIView animateWithDuration:MoveAnimationDuration animations:^{
    copy.transform = CGAffineTransformIdentity;
    CGRect bounds = targetView.bounds;
    copy.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
  }];
  return YES;
}

- (BOOL)addTileViewWithValue:(NSUInteger)value atPosition:(NSUInteger)position
{
  UIView *targetView = [_targetViews objectAtIndex:position];
  if (!targetView) {
    return NO;
  }
  CGRect bounds = targetView.bounds;
  CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
  [self _buildTileViewForTargetView:targetView value:value center:center];
  return YES;
}

- (void)clear
{
  for (UIView *targetView in _targetViews) {
    [targetView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  }
}

- (void)lockPosition:(NSUInteger)position
{
  [self _tileViewAtPosition:position].locked = YES;
}

- (void)setTileViewValid:(BOOL)valid atPosition:(NSUInteger)position
{
  [self _tileViewAtPosition:position].valid = valid;
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];

  [_targetViews enumerateObjectsUsingBlock:^(UIView *targetView, NSUInteger index, BOOL *stop) {
    targetView.bounds = [self _boundsForView:targetView atIndex:index];
    targetView.center = [self _centerForView:targetView atIndex:index];
  }];
}

#pragma mark - Helper Methods

- (CGRect)_boundsForView:(UIView *)view atIndex:(NSUInteger)index
{
  CGRect bounds = CGRectZero;
  bounds.size = GetTileSize(CGRectGetWidth(self.bounds));
  return bounds;
}

- (TileView *)_buildTileViewForTargetView:(UIView *)targetView value:(NSUInteger)value center:(CGPoint)center
{
  TileView *tileView = [[TileView alloc] initWithFrame:CGRectZero];
  tileView.value = value;
  tileView.bounds = targetView.bounds;
  tileView.center = center;
  tileView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(_tapTile:)];
  tapGestureRecognizer.numberOfTapsRequired = 2;
  [tileView addGestureRecognizer:tapGestureRecognizer];
  [targetView addSubview:tileView];
  [targetView.superview bringSubviewToFront:targetView];
  [_delegate boardView:self didAddTileView:tileView atPosition:[_targetViews indexOfObject:targetView]];
  return tileView;
}

- (CGPoint)_centerForView:(UIView *)view atIndex:(NSUInteger)index
{
  CGSize containerSize = self.bounds.size;
  return CGPointMake(GetTileCenter(containerSize.width, (index % NumberOfTiles)),
                     GetTileCenter(containerSize.height, (index / NumberOfTiles)));
}

- (void)_configureBoardView
{
  NSUInteger count = NumberOfTiles * NumberOfTiles;
  NSMutableArray *targetViews = [[NSMutableArray alloc] init];
  UIView *targetView;
  for (NSUInteger i = 0; i < count; ++i) {
    targetView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:targetView];
    [targetViews addObject:targetView];
  }
  _targetViews = [targetViews copy];

  AddDropShadow(self.backgroundView, 2.0);
}

- (UIView *)_emptyTargetViewAtLocation:(CGPoint)location
{
  UIView *view = [self hitTest:location withEvent:nil];
  if ([_targetViews containsObject:view] && ([view.subviews count] == 0)) {
    return view;
  }
  return nil;
}

- (void)_tapTile:(UITapGestureRecognizer *)tapGestureRecognizer
{
  TileView *tileView = (TileView *)tapGestureRecognizer.view;
  NSUInteger position = [_targetViews indexOfObject:tileView.superview];
  if (![_delegate boardView:self canRemoveTileViewAtPosition:position]) {
    return;
  }
  [UIView animateWithDuration:FadeAnimationDuration
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
                     tileView.alpha = 0.0;
                   }
                   completion:^(BOOL finished) {
                     [tileView removeFromSuperview];
                   }];
  [_delegate boardView:self didRemoveTileView:tileView atPosition:position];
}

- (TileView *)_tileViewAtPosition:(NSUInteger)position
{
  UIView *targetView = _targetViews[position];
  for (UIView *subview in targetView.subviews) {
    if ([subview isKindOfClass:[TileView class]]) {
      return (TileView *)subview;
    }
  }
  return nil;
}

@end
