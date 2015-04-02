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

#import <UIKit/UIKit.h>

#import "TileView.h"

@protocol BoardViewDelegate;

@interface BoardView : UIView

@property (nonatomic, strong) IBOutlet UIImageView *backgroundView;
@property (nonatomic, weak) IBOutlet id<BoardViewDelegate> delegate;

- (BOOL)addTileView:(TileView *)tileView;
- (BOOL)addTileViewWithValue:(NSUInteger)value atPosition:(NSUInteger)position;
- (void)clear;
- (void)lockPosition:(NSUInteger)position;
- (void)setTileViewValid:(BOOL)valid atPosition:(NSUInteger)position;

@end

@protocol BoardViewDelegate <NSObject>

- (BOOL)boardView:(BoardView *)boardView canRemoveTileViewAtPosition:(NSUInteger)position;
- (void)boardView:(BoardView *)boardView didAddTileView:(TileView *)tileView atPosition:(NSUInteger)position;
- (void)boardView:(BoardView *)boardView didRemoveTileView:(TileView *)tileView atPosition:(NSUInteger)position;

@end
