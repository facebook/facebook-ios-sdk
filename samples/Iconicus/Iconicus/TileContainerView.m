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

#import "TileContainerView.h"

#import "Utilities.h"

@implementation TileContainerView

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self _configureTileContainerView];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if ((self = [super initWithCoder:decoder])) {
    [self _configureTileContainerView];
  }
  return self;
}

#pragma mark - Public Methods

- (void)resetTileView:(TileView *)tileView withAnimation:(TileResetAnimation)animation
{
  switch (animation) {
    case TileResetAnimationFade:{
      tileView.alpha = 0.0;
      tileView.transform = CGAffineTransformIdentity;
      tileView.center = [self _centerForTileView:tileView];
      [UIView animateWithDuration:FadeAnimationDuration
                            delay:0.0
                          options:UIViewAnimationOptionCurveEaseOut
                       animations:^{
                         tileView.alpha = 1.0;
                       }
                       completion:NULL];
      break;
    }
    case TileResetAnimationMove:{
      [UIView animateWithDuration:MoveAnimationDuration animations:^{
        tileView.transform = CGAffineTransformIdentity;
        tileView.center = [self _centerForTileView:tileView];
      }];
      break;
    }
  }
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];
  for (TileView *tileView in _tileViews) {
    tileView.bounds = [self _boundsForTileView:tileView];
    tileView.center = [self _centerForTileView:tileView];
  }
}

#pragma mark - Helper Methods

- (CGRect)_boundsForTileView:(TileView *)tileView
{
  BOOL layoutTilesHorizontal = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
  CGSize containerSize = self.bounds.size;
  CGFloat containerLength = (layoutTilesHorizontal ? containerSize.width : containerSize.height);
  CGRect bounds = CGRectZero;
  bounds.size = GetTileSize(containerLength);
  return bounds;
}

- (CGPoint)_centerForTileView:(TileView *)tileView
{
  BOOL layoutTilesHorizontal = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
  CGSize containerSize = self.bounds.size;
  CGFloat containerLength = (layoutTilesHorizontal ? containerSize.width : containerSize.height);
  CGFloat center = GetTileCenter(containerLength, tileView.value - 1);
  CGFloat tilePadding = GetTilePadding(containerLength);
  if (layoutTilesHorizontal) {
    return CGPointMake(center, tilePadding + CGRectGetMidY(tileView.bounds));
  } else {
    return CGPointMake(tilePadding + CGRectGetMidX(tileView.bounds), center);
  }
}

- (void)_configureTileContainerView
{
  NSMutableArray *tileViews = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < 9; ++i) {
    TileView *tileView = [[TileView alloc] initWithFrame:CGRectZero];
    AddDropShadow(tileView, 1.0);
    tileView.value = i + 1;
    [self addSubview:tileView];
    [tileViews addObject:tileView];
  }
  _tileViews = [tileViews copy];
}

@end
