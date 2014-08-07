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

#import "FBLikeBoxView.h"

#import "FBColor.h"
#import "FBLikeBoxBorderView.h"

@implementation FBLikeBoxView
{
    FBLikeBoxBorderView *_borderView;
    UILabel *_likeCountLabel;
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
    [_borderView release];
    [_likeCountLabel release];
    [super dealloc];
}

#pragma mark - Properties

- (void)setCaretPosition:(FBLikeBoxCaretPosition)caretPosition
{
    if (_caretPosition != caretPosition) {
        _caretPosition = caretPosition;
        _borderView.caretPosition = _caretPosition;
        [self setNeedsLayout];
        [self invalidateIntrinsicContentSize];
    }
}

- (NSString *)text
{
    return _likeCountLabel.text;
}

- (void)setText:(NSString *)text
{
    if (![_likeCountLabel.text isEqualToString:text]) {
        _likeCountLabel.text = text;
        [self setNeedsLayout];
        [self invalidateIntrinsicContentSize];
    }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    return _borderView.intrinsicContentSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    _borderView.frame = bounds;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return [_borderView sizeThatFits:size];
}

#pragma mark - Helper Methods

- (void)_initializeContent
{
    _borderView = [[FBLikeBoxBorderView alloc] initWithFrame:CGRectZero];
    [self addSubview:_borderView];

    _likeCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _likeCountLabel.font = [UIFont systemFontOfSize:11.0];
    _likeCountLabel.textAlignment = NSTextAlignmentCenter;
    _likeCountLabel.textColor = FBUIColorWithRGB(0x6A, 0x71, 0x80);
    _borderView.contentView = _likeCountLabel;
}

@end
