/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
