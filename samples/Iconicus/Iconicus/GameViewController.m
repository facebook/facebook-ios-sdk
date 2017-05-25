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

#import "GameViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "GameController.h"
#import "ToastView.h"
#import "Utilities.h"

@implementation GameViewController
{
  CGPoint _dragOffset;
  GameController *_gameController;
  BFAppLinkReturnToRefererController *_returnToRefererController;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self _updateGameController:[GameController generate]];

  for (TileView *tileView in self.tileContainerView.tileViews) {
    UILongPressGestureRecognizer *recognizer;
    recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_dragTile:)];
    recognizer.minimumPressDuration = 0.0;
    [tileView addGestureRecognizer:recognizer];
  }
}

#pragma mark - Public Methods

- (BOOL)loadGameFromAppLinkURL:(BFURL *)appLinkURL
{
  if (![self loadGameFromStringRepresentationWithData:appLinkURL.targetQueryParameters[@"data"]
                                               locked:appLinkURL.targetQueryParameters[@"locked"]]) {
    return NO;
  }

  if (appLinkURL.appLinkReferer) {
    if (!_returnToRefererController) {
      _returnToRefererController = [[BFAppLinkReturnToRefererController alloc] init];
      [self.view addSubview:_returnToRefererController.view];
    }

    // only show the back to referer navigation-banner when refererURL is set.
    // In this version of Bolts, we will need to change the size of this view frame manually to none-zero.
    _returnToRefererController.view = self.returnToRefererView;
    [_returnToRefererController showViewForRefererAppLink:appLinkURL.appLinkReferer];
  }

  return YES;
}

- (BOOL)loadGameFromStringRepresentationWithData:(NSString *)data locked:(NSString *)locked
{
  GameController *gameController = [GameController gameControllerFromStringRepresentationWithData:data locked:locked];
  if (!gameController) {
    return NO;
  }
  [self _updateGameController:gameController];
  return YES;
}

#pragma mark - Actions

- (void)copyGameURL:(id)sender
{
  [UIPasteboard generalPasteboard].URL = [self _gameURL];
  [ToastView showInWindow:self.view.window text:@"Game URL copied to pasteboard." duration:2.0];
}

- (void)reset:(id)sender
{
  [_gameController reset];
  [self _updateGameController:_gameController];
}

- (IBAction)startGame:(id)sender
{
  [self _updateGameController:[GameController generate]];
}

#pragma mark - BoardViewDelegate

- (BOOL)boardView:(BoardView *)boardView canRemoveTileViewAtPosition:(NSUInteger)position
{
  BOOL result = ![_gameController valueAtPositionIsLocked:position];
  return result;
}

- (void)boardView:(BoardView *)boardView didAddTileView:(TileView *)tileView atPosition:(NSUInteger)position
{
  [_gameController setValue:tileView.value forPosition:position];
  [self _updateShareContent];
  [self _updateTileValidity];
}

- (void)boardView:(BoardView *)boardView didRemoveTileView:(TileView *)tileView atPosition:(NSUInteger)position
{
  [_gameController setValue:0 forPosition:position];
  [self _updateShareContent];
  [self _updateTileValidity];
}

#pragma mark - Helper Methods

- (void)_dragTile:(UIGestureRecognizer *)gestureRecognizer
{
  TileView *tileView = (TileView *)gestureRecognizer.view;
  CGPoint location = [gestureRecognizer locationInView:[tileView superview]];
  switch (gestureRecognizer.state) {
    case UIGestureRecognizerStateBegan:{
      // highlight the view
      [tileView.superview bringSubviewToFront:tileView];
      CGPoint center = tileView.center;
      _dragOffset = CGPointMake(center.x - location.x, center.y - location.y - DragOffsetY);
      [tileView.superview layoutIfNeeded];
      [UIView animateWithDuration:MoveAnimationDuration animations:^{
        tileView.transform = CGAffineTransformMakeScale(HighlightScale, HighlightScale);
        tileView.center = CGPointMake(location.x + _dragOffset.x, location.y + _dragOffset.y);
      }];
      break;
    }
    case UIGestureRecognizerStateChanged:{
      // drag the tile
      tileView.center = CGPointMake(location.x + _dragOffset.x, location.y + _dragOffset.y);
      break;
    }
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
    {
      // move the tile back to where it came from
      [self.tileContainerView resetTileView:tileView withAnimation:TileResetAnimationMove];
      break;
    }
    case UIGestureRecognizerStateEnded:{
      // attempt to add the tile to the board
      tileView.center = CGPointMake(location.x + _dragOffset.x, location.y + _dragOffset.y);
      BoardView *boardView = self.boardView;
      if ([boardView addTileView:tileView]) {
        // fade in the replacement tile (move this one back to where it came from after adding the tile to the board)
        [self.tileContainerView resetTileView:tileView withAnimation:TileResetAnimationFade];
      } else {
        // invalid drop position, move the tile back to where it came from
        [self.tileContainerView resetTileView:tileView withAnimation:TileResetAnimationMove];
      }
      break;
    }
    case UIGestureRecognizerStatePossible:{
      // do nothing
      break;
    }
  }
}

- (NSURL *)_gameURL
{
  NSString *appLinkURLBaseString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppLinkURL"];
  NSDictionary *params = @{ @"data": [_gameController stringRepresentation] };
  NSString *queryString = [FBSDKUtility queryStringWithDictionary:params error:NULL];
  NSString *shareURLString = [NSString stringWithFormat:@"%@?%@", appLinkURLBaseString, queryString];
  return [NSURL URLWithString:shareURLString];
}

- (void)_updateGameController:(GameController *)gameController
{
  _gameController = gameController;
  BoardView *boardView = self.boardView;
  boardView.delegate = nil;
  [boardView clear];
  for (NSUInteger position = 0; position < NumberOfTiles * NumberOfTiles; ++position) {
    NSUInteger value = [_gameController valueAtPosition:position];
    if (value != 0) {
      [boardView addTileViewWithValue:value atPosition:position];
      if ([gameController valueAtPositionIsLocked:position]) {
        [boardView lockPosition:position];
      }
    }
  }
  boardView.delegate = self;
  [self _updateShareContent];
  [self _updateTileValidity];
}

- (void)_updateShareContent
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [self _gameURL];
  self.shareButton.shareContent = content;
  self.sendButton.shareContent = content;
}

- (void)_updateTileValidity
{
  BoardView *boardView = self.boardView;
  for (NSUInteger position = 0; position < NumberOfTiles * NumberOfTiles; ++position) {
    [boardView setTileViewValid:[_gameController valueAtPositionIsValid:position] atPosition:position];
  }
}

@end
