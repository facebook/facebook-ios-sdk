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

#import "TileView.h"

@implementation TileView
{
  UIImageView *_backgroundView;
  UIImageView *_imageView;
}

#pragma mark - Class Methods

+ (UIImage *)backgroundImage
{
  static UIImage *_backgroundImage = nil;
  if (!_backgroundImage) {
    _backgroundImage = [UIImage imageNamed:@"TileBackground"];
  }
  return _backgroundImage;
}

+ (UIImage *)backgroundInvalidImage
{
  static UIImage *_backgroundInvalidImage = nil;
  if (!_backgroundInvalidImage) {
    _backgroundInvalidImage = [UIImage imageNamed:@"TileBackgroundInvalid"];
  }
  return _backgroundInvalidImage;
}

+ (UIImage *)backgroundLockedImage
{
  static UIImage *_backgroundLockedImage = nil;
  if (!_backgroundLockedImage) {
    _backgroundLockedImage = [UIImage imageNamed:@"TileBackgroundLocked"];
  }
  return _backgroundLockedImage;
}

+ (CGSize)defaultSize
{
  return [self backgroundImage].size;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self _configureTileView];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if ((self = [super initWithCoder:decoder])) {
    [self _configureTileView];
  }
  return self;
}

#pragma mark - Properties

- (void)setLocked:(BOOL)locked
{
  if (_locked != locked) {
    _locked = locked;
    [self _updateBackground];
  }
}

- (void)setValid:(BOOL)valid
{
  if (_valid != valid) {
    _valid = valid;
    [self _updateBackground];
  }
}

- (void)setValue:(NSUInteger)value
{
  if (_value != value) {
    _value = value;
    _imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"Tile%lu", (unsigned long)value]];
  }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
  return [[self class] defaultSize];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  CGRect bounds = self.bounds;
  _backgroundView.frame = bounds;
  _imageView.frame = CGRectInset(bounds, 4.0, 4.0);
}

#pragma mark - Helper Methods

- (void)_configureTileView
{
  _valid = YES;
  _backgroundView = [[UIImageView alloc] initWithImage:[[self class] backgroundImage]];
  [self addSubview:_backgroundView];
  _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  [self addSubview:_imageView];
  CGRect bounds = self.bounds;
  if (CGRectIsEmpty(bounds)) {
    bounds.size = [self intrinsicContentSize];
    self.bounds = bounds;
  }
}

- (void)_updateBackground
{
  if (_locked) {
    _backgroundView.image = [[self class] backgroundLockedImage];
  } else if (!_valid) {
    _backgroundView.image = [[self class] backgroundInvalidImage];
  } else {
    _backgroundView.image = [[self class] backgroundImage];
  }
}

@end
