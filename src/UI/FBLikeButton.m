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

#import "FBLikeButton.h"

#import "FBDynamicFrameworkLoader.h"
#import "FBLikeButtonBackgroundPNG.h"
#import "FBLikeButtonBackgroundSelectedPNG.h"
#import "FBLikeButtonIconPNG.h"
#import "FBLikeButtonIconSelectedPNG.h"
#import "FBUIHelpers.h"

#define kFBLikeButtonContentToSizeRatio (28.0 / 52.0)

#define kFBLikeButtonAnimationDuration 0.2
#define kFBLikeButtonAnimationSpringDamping 0.3
#define kFBLikeButtonAnimationSpringVelocity 0.2

@implementation FBLikeButton
{
    UIImage *_iconImageNormal;
    UIImage *_iconImageSelected;
    UIImageView *_iconImageView;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self _initializeContent];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _initializeContent];
}

- (void)dealloc
{
    [_iconImageNormal release];
    [_iconImageSelected release];
    [_iconImageView release];
    [super dealloc];
}

#pragma mark - Properties

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

#pragma mark - Public API

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected != selected) {
        if (animated) {
            Class CATransactionClass = [FBDynamicFrameworkLoader loadClass:@"CATransaction" withFramework:@"QuartzCore"];
            CFTimeInterval duration = ([CATransactionClass animationDuration] ?: kFBLikeButtonAnimationDuration);
            UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
            [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
                CGPoint iconImageViewCenter = _iconImageView.center;
                _iconImageView.frame = CGRectMake(iconImageViewCenter.x, iconImageViewCenter.y, 0.0, 0.0);
            } completion:^(BOOL animateOutFinished) {
                [super setSelected:selected];
                [self _updateIconForState];

                void(^animations)(void) = ^{
                    _iconImageView.frame = [self imageRectForContentRect:UIEdgeInsetsInsetRect(self.bounds, self.contentEdgeInsets)];
                };
                if ([UIView respondsToSelector:@selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)]) {
                    [UIView animateWithDuration:(duration * 2)
                                          delay:0.0
                         usingSpringWithDamping:kFBLikeButtonAnimationSpringDamping
                          initialSpringVelocity:kFBLikeButtonAnimationSpringVelocity
                                        options:options
                                     animations:animations
                                     completion:NULL];
                } else {
                    [UIView animateWithDuration:(duration * 2)
                                          delay:0.0
                                        options:options
                                     animations:animations
                                     completion:NULL];
                }
            }];
        } else {
            [super setSelected:selected];
            [self _updateIconForState];
        }
    }
}

#pragma mark - Layout

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    contentRect.size.width = CGRectGetHeight(contentRect);
    return contentRect;
}

- (CGSize)intrinsicContentSize
{
    return [self _sizeWithTitleSize:self.titleLabel.intrinsicContentSize];
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    UIEdgeInsets contentEdgeInsets = [self _contentEdgeInsetsForHeight:CGRectGetHeight(bounds)];

    if ([_iconImageView.layer.animationKeys count] == 0) {
        _iconImageView.frame = [self imageRectForContentRect:UIEdgeInsetsInsetRect(bounds, contentEdgeInsets)];
    }

    self.contentEdgeInsets = contentEdgeInsets;

    [super layoutSubviews];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    UIFont *font = self.titleLabel.font;
    CGSize constrainedTitleSize = FBEdgeInsetsInsetSize(size, self.titleEdgeInsets);
    CGSize normalTitleTextSize = FBTextSize([self titleForState:UIControlStateNormal],
                                            font,
                                            constrainedTitleSize,
                                            NSLineBreakByClipping);
    CGSize selectedTitleTextSize = FBTextSize([self titleForState:UIControlStateSelected],
                                              font,
                                              constrainedTitleSize,
                                              NSLineBreakByClipping);
    CGSize normalSize = [self _sizeWithTitleSize:normalTitleTextSize];
    CGSize selectedSize = [self _sizeWithTitleSize:selectedTitleTextSize];

    return CGSizeMake(MAX(normalSize.width, selectedSize.width),
                      MAX(normalSize.height, selectedSize.height));
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGRect imageRect = [self imageRectForContentRect:contentRect];
    CGFloat titleX = CGRectGetMaxX(imageRect);
    CGRect titleRect = CGRectMake(titleX, CGRectGetMinY(contentRect), CGRectGetWidth(contentRect) - titleX, CGRectGetHeight(contentRect));
    UIEdgeInsets titleEdgeInsets = self.titleEdgeInsets;
    titleEdgeInsets.left += self.contentEdgeInsets.left;
    return UIEdgeInsetsInsetRect(titleRect, titleEdgeInsets);
}

#pragma mark - Helper Methods

- (UIEdgeInsets)_contentEdgeInsetsForContentHeight:(CGFloat)contentHeight
{
    CGFloat height = contentHeight / kFBLikeButtonContentToSizeRatio;
    CGFloat inset = floorf((height - contentHeight) / 2);
    return UIEdgeInsetsMake(inset, inset, inset, inset);
}

- (UIEdgeInsets)_contentEdgeInsetsForHeight:(CGFloat)height
{
    CGFloat inset = floorf(height * kFBLikeButtonContentToSizeRatio / 2);
    return UIEdgeInsetsMake(inset, inset, inset, 0.0);
}

- (void)_initializeContent
{
    self.adjustsImageWhenHighlighted = NO;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

    UIImage *image;
    UIEdgeInsets backgroundCapInsets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);

    image = [[FBLikeButtonBackgroundPNG image] resizableImageWithCapInsets:backgroundCapInsets];
    [self setBackgroundImage:image forState:UIControlStateNormal];

    image = [[FBLikeButtonBackgroundSelectedPNG image] resizableImageWithCapInsets:backgroundCapInsets];
    [self setBackgroundImage:image forState:UIControlStateSelected];

    _iconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self addSubview:_iconImageView];

    _iconImageNormal = [[[FBLikeButtonIconPNG image] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch] retain];
    _iconImageSelected = [[[FBLikeButtonIconSelectedPNG image] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch] retain];

    [self setTitle:NSLocalizedString(@"Like", @"FBLB:LikeButton") forState:UIControlStateNormal];
    [self setTitle:NSLocalizedString(@"Liked", @"FBLB:LikeButton") forState:UIControlStateSelected];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];

    [self _updateIconForState];
}

- (CGSize)_sizeWithTitleSize:(CGSize)titleSize
{
    UIEdgeInsets imageEdgeInsets = self.imageEdgeInsets;
    UIEdgeInsets titleEdgeInsets = self.titleEdgeInsets;

    titleSize = CGSizeMake(ceilf(titleSize.width + 0.5), ceilf(titleSize.height));
    UIEdgeInsets contentEdgeInsets = [self _contentEdgeInsetsForContentHeight:titleSize.height];

    CGSize imageSize = CGSizeMake(titleSize.height, titleSize.height);

    CGSize insetImageSize = FBEdgeInsetsOutsetSize(imageSize, imageEdgeInsets);
    CGSize insetTitleSize = FBEdgeInsetsOutsetSize(titleSize, titleEdgeInsets);

    CGSize contentSize = CGSizeMake(insetImageSize.width + contentEdgeInsets.left + insetTitleSize.width,
                                    MAX(insetImageSize.height, insetTitleSize.height));

    return FBEdgeInsetsOutsetSize(contentSize, contentEdgeInsets);
}

- (void)_updateIconForState
{
    UIControlState state = self.state;
    if (state & UIControlStateSelected) {
        _iconImageView.image = _iconImageSelected;
    } else {
        _iconImageView.image = _iconImageNormal;
    }
    [self invalidateIntrinsicContentSize];
}

@end
