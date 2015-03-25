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

#import "SIMainView.h"

@implementation SIMainView
{
  NSArray *_imageViews;
}

#pragma mark - Properties

- (void)setImages:(NSArray *)images
{
  if (![_images isEqualToArray:images]) {
    _images = [images copy];

    [_imageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSMutableArray *imageViews = [[NSMutableArray alloc] initWithCapacity:[images count]];
    UIScrollView *scrollView = self.scrollView;
    for (UIImage *image in images) {
      UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
      [scrollView addSubview:imageView];
      [imageViews addObject:imageView];
    }
    _imageViews = imageViews;
    [self setNeedsLayout];
  }
}

- (void)setPhoto:(SIPhoto *)photo
{
  if (![_photo isEqual:photo]) {
    _photo = photo;
    _titleLabel.text = photo.title;
  }
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];

  UIScrollView *scrollView = self.scrollView;
  CGSize scrollViewSize = scrollView.bounds.size;
  scrollView.contentSize = CGSizeMake(scrollViewSize.width * _imageViews.count,
                                      scrollViewSize.height);
  [_imageViews enumerateObjectsUsingBlock:^(UIView *imageView, NSUInteger idx, BOOL *stop) {
    CGSize imageViewSize = [imageView sizeThatFits:scrollViewSize];
    imageView.frame = CGRectMake(scrollViewSize.width * idx + floorf((scrollViewSize.width - imageViewSize.width) / 2),
                                 0.0,
                                 imageViewSize.height,
                                 imageViewSize.height);
  }];
}

@end
