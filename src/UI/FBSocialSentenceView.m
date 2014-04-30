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

#import "FBSocialSentenceView.h"

#import "FBDynamicFrameworkLoader.h"
#import "FBUIHelpers.h"

#define kFBSocialSentenceViewAnimationDuration 0.2

@implementation FBSocialSentenceView
{
    UILabel *_textLabel;
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
    [_text release];
    [_textLabel release];
    [super dealloc];
}

#pragma mark - Properties

- (void)setText:(NSString *)text
{
    [self setText:text animated:NO];
    [self invalidateIntrinsicContentSize];
}

- (NSTextAlignment)textAlignment
{
    return _textLabel.textAlignment;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    _textLabel.textAlignment = textAlignment;
    switch (textAlignment) {
        case NSTextAlignmentLeft:{
            _textLabel.layer.anchorPoint = CGPointMake(0.0, 0.5);
            break;
        }
        case NSTextAlignmentRight:{
            _textLabel.layer.anchorPoint = CGPointMake(1.0, 0.5);
            break;
        }
        case NSTextAlignmentCenter:
        case NSTextAlignmentJustified:
        case NSTextAlignmentNatural:{
            _textLabel.layer.anchorPoint = CGPointMake(0.5, 0.5);
            break;
        }
    }
}

- (UIColor *)textColor
{
    return _textLabel.textColor;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textLabel.textColor = textColor;
}

#pragma mark - Public API

- (void)setText:(NSString *)text animated:(BOOL)animated
{
    if (![_text isEqualToString:text]) {
        _text = [text copy];

        if (animated) {
            Class CATransactionClass = [FBDynamicFrameworkLoader loadClass:@"CATransaction" withFramework:@"QuartzCore"];
            CFTimeInterval duration = ([CATransactionClass animationDuration] ?: kFBSocialSentenceViewAnimationDuration);
            CFTimeInterval delay = 0.0;
            UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
            [UIView animateWithDuration:duration delay:delay options:options animations:^{
                _textLabel.transform = CGAffineTransformMakeScale(0.1, 0.1);
            } completion:^(BOOL finished) {
                _textLabel.text = text;

                [UIView animateWithDuration:duration delay:delay options:options animations:^{
                    _textLabel.transform = CGAffineTransformIdentity;
                } completion:NULL];
            }];
        } else {
            _textLabel.text = text;
        }
    }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    return _textLabel.intrinsicContentSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _textLabel.frame = self.bounds;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return FBTextSize(_text, _textLabel.font, size, NSLineBreakByWordWrapping);
}

#pragma mark - Helper Methods

- (void)_initializeContent
{
    _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _textLabel.font = [UIFont systemFontOfSize:11.0];
    _textLabel.numberOfLines = 2;
    [self addSubview:_textLabel];
}

@end
