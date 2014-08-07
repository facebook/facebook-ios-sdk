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

#import "FBLikeControl.h"

#import "FBAppEvents+Internal.h"
#import "FBDialogs+Internal.h"
#import "FBLikeActionController.h"
#import "FBLikeBoxView.h"
#import "FBLikeButton.h"
#import "FBViewImpressionTracker.h"

#define kFBLikeControlAnimationDuration 0.2
#define kFBLikeControlSocialSentenceAnimationOffset 10.0

NSString *NSStringFromFBLikeControlAuxiliaryPosition(FBLikeControlAuxiliaryPosition auxiliaryPosition)
{
    switch (auxiliaryPosition) {
        case FBLikeControlAuxiliaryPositionBottom:
            return @"bottom";
        case FBLikeControlAuxiliaryPositionInline:
            return @"inline";
        case FBLikeControlAuxiliaryPositionTop:
            return @"top";
    }
    return nil;
}

NSString *NSStringFromFBLikeControlHorizontalAlignment(FBLikeControlHorizontalAlignment horizontalAlignment)
{
    switch (horizontalAlignment) {
        case FBLikeControlHorizontalAlignmentCenter:
            return @"center";
        case FBLikeControlHorizontalAlignmentLeft:
            return @"left";
        case FBLikeControlHorizontalAlignmentRight:
            return @"right";
    }
    return nil;
}

NSString *NSStringFromFBLikeControlStyle(FBLikeControlStyle style)
{
    switch (style) {
        case FBLikeControlStyleBoxCount:
            return @"box_count";
        case FBLikeControlStyleButton:
            return @"button";
        case FBLikeControlStyleStandard:
            return @"standard";
    }
    return nil;
}

typedef struct FBLikeControlLayout
{
    CGSize contentSize;
    CGRect likeButtonFrame;
    CGRect auxiliaryViewFrame;
} FBLikeControlLayout;

typedef CGSize (^fb_like_control_sizing_block_t)(UIView *subview, CGSize constrainedSize);

@implementation FBLikeControl
{
    FBLikeActionController *_likeActionController;
    FBLikeBoxView *_likeBoxView;
    FBLikeButton *_likeButton;
    UIView *_likeButtonContainer;
    UILabel *_socialSentenceLabel;
}

#pragma mark - Class Methods

+ (BOOL)dialogIsAvailable
{
    return [FBDialogs canPresentLikeDialog];
}

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self _initializeContent];
        if (CGRectEqualToRect(frame, CGRectZero)) {
            [self sizeToFit];
        }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_likeButton removeTarget:self action:@selector(_handleLikeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [_likeActionController endContentAccess];

    [_likeActionController release];
    [_likeBoxView release];
    [_likeButton release];
    [_likeButtonContainer release];
    [_objectID release];
    [_socialSentenceLabel release];
    [super dealloc];
}

#pragma mark - Properties

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    _likeButtonContainer.backgroundColor = backgroundColor;
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    if (![_foregroundColor isEqual:foregroundColor]) {
        [_foregroundColor release];
        _foregroundColor = [foregroundColor retain];
        [_likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _socialSentenceLabel.textColor = foregroundColor;
    }
}

- (void)setLikeControlAuxiliaryPosition:(FBLikeControlAuxiliaryPosition)likeControlAuxiliaryPosition
{
    if (_likeControlAuxiliaryPosition != likeControlAuxiliaryPosition) {
        _likeControlAuxiliaryPosition = likeControlAuxiliaryPosition;
        [self _updateLikeBoxCaretPosition];
        [self setNeedsLayout];
        [self setNeedsUpdateConstraints];
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setLikeControlHorizontalAlignment:(FBLikeControlHorizontalAlignment)likeControlHorizontalAlignment
{
    if (_likeControlHorizontalAlignment != likeControlHorizontalAlignment) {
        _likeControlHorizontalAlignment = likeControlHorizontalAlignment;
        [self _updateLikeBoxCaretPosition];
        [self setNeedsLayout];
        [self setNeedsUpdateConstraints];
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setLikeControlStyle:(FBLikeControlStyle)likeControlStyle
{
    if (_likeControlStyle != likeControlStyle) {
        _likeControlStyle = likeControlStyle;
        [self _updateLikeBoxCaretPosition];
        [self setNeedsLayout];
        [self setNeedsUpdateConstraints];
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setObjectID:(NSString *)objectID
{
    if (![_objectID isEqualToString:objectID]) {
        [_objectID release];
        _objectID = [objectID copy];
        [self _resetLikeActionController];

        _likeButton.selected = _likeActionController.objectIsLiked;
        _socialSentenceLabel.text = _likeActionController.socialSentence;
        _likeBoxView.text = _likeActionController.likeCountString;

        [self setNeedsLayout];
    }
}

- (void)setOpaque:(BOOL)opaque
{
    [super setOpaque:opaque];
    _likeButtonContainer.opaque = opaque;
}

#pragma mark - Layout

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    NSDictionary *analyticsParameters = [self _analyticsParameters];
    FBViewImpressionTracker *impressionTracker = [FBViewImpressionTracker impressionTrackerWithEventName:FBAppEventNameFBLikeControlImpression];
    [impressionTracker logImpressionWithView:self
                                  identifier:self.objectID
                                  parameters:analyticsParameters];
}

- (CGSize)intrinsicContentSize
{
    CGFloat width = self.preferredMaxLayoutWidth;
    if (width == 0) {
        width = CGFLOAT_MAX;
    }
    CGRect bounds = CGRectMake(0.0, 0.0, width, CGFLOAT_MAX);
    return [self _layoutWithBounds:bounds subviewSizingBlock:^CGSize(UIView *subview, CGSize constrainedSize) {
        if ([subview respondsToSelector:@selector(setPreferredMaxLayoutWidth:)]) {
            [(id)subview setPreferredMaxLayoutWidth:constrainedSize.width];
        }
        return subview.intrinsicContentSize;
    }].contentSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if ([FBLikeActionController isDisabled]) {
        _likeBoxView.hidden = YES;
        _likeButton.hidden = YES;
        _likeButtonContainer.hidden = YES;
        _socialSentenceLabel.hidden = YES;
        return;
    }

    CGRect bounds = self.bounds;
    FBLikeControlLayout layout = [self _layoutWithBounds:bounds subviewSizingBlock:^CGSize(UIView *subview, CGSize constrainedSize) {
        return [subview sizeThatFits:constrainedSize];
    }];

    UIView *auxiliaryView = [self _auxiliaryView];
    _likeBoxView.hidden = (_likeBoxView != auxiliaryView);
    _socialSentenceLabel.hidden = (_socialSentenceLabel != auxiliaryView);

    _likeButtonContainer.frame = layout.likeButtonFrame;
    _likeButton.frame = _likeButtonContainer.bounds;
    auxiliaryView.frame = layout.auxiliaryViewFrame;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    switch (self.likeControlAuxiliaryPosition) {
        case FBLikeControlAuxiliaryPositionInline:{
            size.height = MAX(size.height, CGRectGetHeight(self.bounds));
            break;
        }
        case FBLikeControlAuxiliaryPositionTop:
        case FBLikeControlAuxiliaryPositionBottom:{
            size.width = MAX(size.width, CGRectGetWidth(self.bounds));
            break;
        }
    }

    CGRect bounds = CGRectMake(0.0, 0.0, size.width, size.height);
    return [self _layoutWithBounds:bounds subviewSizingBlock:^CGSize(UIView *subview, CGSize constrainedSize) {
        return [subview sizeThatFits:constrainedSize];
    }].contentSize;
}

#pragma mark - Helper Methods

- (NSDictionary *)_analyticsParameters
{
    return @{
      @"auxiliary_position": NSStringFromFBLikeControlAuxiliaryPosition(self.likeControlAuxiliaryPosition),
      @"horizontal_alignment": NSStringFromFBLikeControlHorizontalAlignment(self.likeControlHorizontalAlignment),
      @"object_id": (self.objectID ?: [NSNull null]),
      @"sound_enabled": @(self.soundEnabled),
      @"style": NSStringFromFBLikeControlStyle(self.likeControlStyle),
      };
}

- (UIView *)_auxiliaryView
{
    switch (_likeControlStyle) {
        case FBLikeControlStyleStandard:{
            return (_socialSentenceLabel.text.length == 0 ? nil : _socialSentenceLabel);
        }
        case FBLikeControlStyleBoxCount:{
            return (_likeActionController.likeCountString == nil ? nil : _likeBoxView);
        }
        case FBLikeControlStyleButton:{
            return nil;
        }
    }
    return nil;
}

- (CGFloat)_auxiliaryViewPadding
{
    switch (_likeControlStyle) {
        case FBLikeControlStyleStandard:{
            return 8.0;
        }
        case FBLikeControlStyleBoxCount:{
            return 0.0;
        }
        case FBLikeControlStyleButton:{
            return 0.0;
        }
    }
    return 0.0;
}

- (void)_handleLikeActionControllerDidDisableNotification:(NSNotification *)notification
{
    [self setNeedsLayout];
}

- (void)_handleLikeActionControllerDidUpdateNotification:(NSNotification *)notification
{
    FBLikeActionController *likeActionController = (FBLikeActionController *)notification.object;
    NSString *objectID = likeActionController.objectID;
    if ([self.objectID isEqualToString:objectID]) {
        BOOL animated = [notification.userInfo[FBLikeActionControllerAnimatedKey] boolValue];

        [_likeButton setSelected:likeActionController.objectIsLiked animated:animated];
        _likeBoxView.text = _likeActionController.likeCountString;

        if (animated) {
            void(^hideView)(UIView *) = ^(UIView *view){
                view.alpha = 0.0;
                CGRect frame = view.frame;
                frame.origin.y += kFBLikeControlSocialSentenceAnimationOffset;
                view.frame = frame;
            };
            [UIView animateWithDuration:kFBLikeControlAnimationDuration animations:^{
                hideView(_socialSentenceLabel);
            } completion:^(BOOL finished) {
                _socialSentenceLabel.text = likeActionController.socialSentence;
                [self setNeedsLayout];
                [self setNeedsUpdateConstraints];
                [self invalidateIntrinsicContentSize];
                [self layoutIfNeeded];
                hideView(_socialSentenceLabel);

                [UIView animateWithDuration:kFBLikeControlAnimationDuration animations:^{
                    _socialSentenceLabel.alpha = 1.0;
                    [self setNeedsLayout];
                    [self layoutIfNeeded];
                }];
            }];
        } else {
            _socialSentenceLabel.text = likeActionController.socialSentence;
            [self setNeedsLayout];
            [self setNeedsUpdateConstraints];
            [self invalidateIntrinsicContentSize];
        }

        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)_handleLikeButtonTap:(FBLikeButton *)likeButton
{
    [self _handleLikeButtonTouchUp:likeButton];
    FBLikeActionController *actionController = [FBLikeActionController likeActionControllerForObjectID:_objectID];
    [actionController toggleLikeWithSoundEnabled:self.isSoundEnabled analyticsParameters:[self _analyticsParameters]];
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)_handleLikeButtonTouchDown:(FBLikeButton *)likeButton
{
    [UIView animateWithDuration:0.1 animations:^{
        _likeButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
    }];
}

- (void)_handleLikeButtonTouchUp:(FBLikeButton *)likeButton
{
    [UIView animateWithDuration:0.05 animations:^{
        _likeButton.transform = CGAffineTransformIdentity;
    }];
}

- (void)_initializeContent
{
    self.soundEnabled = YES;

    self.backgroundColor = [UIColor clearColor];
    _foregroundColor = [[UIColor blackColor] retain];

    _likeButtonContainer = [[UIView alloc] initWithFrame:CGRectZero];
    _likeButtonContainer.backgroundColor = self.backgroundColor;
    _likeButtonContainer.opaque = self.opaque;
    [self addSubview:_likeButtonContainer];

    _likeButton = [[FBLikeButton alloc] initWithFrame:CGRectZero];
    [_likeButton addTarget:self action:@selector(_handleLikeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [_likeButton addTarget:self
                    action:@selector(_handleLikeButtonTouchDown:)
          forControlEvents:(//UIControlEventTouchDragEnter |
                            UIControlEventTouchDown)];
    [_likeButton addTarget:self
                    action:@selector(_handleLikeButtonTouchUp:)
          forControlEvents:(UIControlEventTouchCancel |
                            //UIControlEventTouchDragExit |
                            UIControlEventTouchUpOutside)];
    [_likeButtonContainer addSubview:_likeButton];

    _socialSentenceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _socialSentenceLabel.font = [UIFont systemFontOfSize:11.0];
    _socialSentenceLabel.numberOfLines = 2;
    [self addSubview:_socialSentenceLabel];

    _likeBoxView = [[FBLikeBoxView alloc] initWithFrame:CGRectZero];
    [self addSubview:_likeBoxView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_likeActionControllerDidResetNotification:)
                                                 name:FBLikeActionControllerDidResetNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleLikeActionControllerDidDisableNotification:)
                                                 name:FBLikeActionControllerDidDisableNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleLikeActionControllerDidUpdateNotification:)
                                                 name:FBLikeActionControllerDidUpdateNotification
                                               object:nil];
}

static void FBLikeControlApplyHorizontalAlignment(CGRect *frameRef, CGRect bounds, FBLikeControlHorizontalAlignment alignment)
{
    if (frameRef == NULL) {
        return;
    }

    CGRect frame = *frameRef;
    switch (alignment) {
        case FBLikeControlHorizontalAlignmentLeft:{
            frame.origin.x = CGRectGetMinX(bounds);
            break;
        }
        case FBLikeControlHorizontalAlignmentCenter:{
            frame.origin.x = CGRectGetMinX(bounds) + floorf((CGRectGetWidth(bounds) - CGRectGetWidth(frame)) / 2);
            break;
        }
        case FBLikeControlHorizontalAlignmentRight:{
            frame.origin.x = CGRectGetMinX(bounds) + CGRectGetWidth(bounds) - CGRectGetWidth(frame);
            break;
        }
    }
    *frameRef = frame;
}

static CGFloat FBLikeControlPaddedDistance(CGFloat distance, CGFloat padding, BOOL includeDistance)
{
    return (distance == 0.0 ? 0.0 : (includeDistance ? distance : 0.0) + padding);
}

static CGSize FBLikeControlCalculateContentSize(FBLikeControlLayout layout)
{
    return CGSizeMake(MAX(CGRectGetMaxX(layout.likeButtonFrame), CGRectGetMaxX(layout.auxiliaryViewFrame)),
                      MAX(CGRectGetMaxY(layout.likeButtonFrame), CGRectGetMaxY(layout.auxiliaryViewFrame)));

}

- (FBLikeControlLayout)_layoutWithBounds:(CGRect)bounds subviewSizingBlock:(fb_like_control_sizing_block_t)subviewSizingBlock
{
    FBLikeControlLayout layout;

    CGSize likeButtonSize = subviewSizingBlock(_likeButton, bounds.size);
    layout.likeButtonFrame = CGRectMake(CGRectGetMinX(bounds),
                                        CGRectGetMinY(bounds),
                                        likeButtonSize.width,
                                        likeButtonSize.height);
    layout.auxiliaryViewFrame = CGRectZero;

    UIView *auxiliaryView = [self _auxiliaryView];
    CGFloat auxiliaryViewPadding = [self _auxiliaryViewPadding];
    CGSize auxiliaryViewSize = CGSizeZero;
    switch (self.likeControlAuxiliaryPosition) {
        case FBLikeControlAuxiliaryPositionInline:{
            if (auxiliaryView) {
                auxiliaryViewSize = CGSizeMake(CGRectGetWidth(bounds) - auxiliaryViewPadding - CGRectGetWidth(layout.likeButtonFrame),
                                               CGRectGetHeight(bounds));
                auxiliaryViewSize = subviewSizingBlock(auxiliaryView, auxiliaryViewSize);

                layout.auxiliaryViewFrame = CGRectMake(CGRectGetMinX(bounds),
                                                       CGRectGetMinY(bounds),
                                                       auxiliaryViewSize.width,
                                                       MAX(auxiliaryViewSize.height, CGRectGetHeight(layout.likeButtonFrame)));
            }

            // align the views next to each other for sizing
            FBLikeControlApplyHorizontalAlignment(&layout.likeButtonFrame, bounds, FBLikeControlHorizontalAlignmentLeft);
            if (auxiliaryView) {
                layout.auxiliaryViewFrame.origin.x = CGRectGetMaxX(layout.likeButtonFrame) + auxiliaryViewPadding;
            }

            // calculate the size before offsetting the horizontal alignment, using the total calculated width
            layout.contentSize = FBLikeControlCalculateContentSize(layout);

            // layout the subviews next to each other
            switch (self.likeControlHorizontalAlignment) {
                case FBLikeControlHorizontalAlignmentLeft:{
                    // already done
                    break;
                }
                case FBLikeControlHorizontalAlignmentCenter:{
                    layout.likeButtonFrame.origin.x = floorf((CGRectGetWidth(bounds) - layout.contentSize.width) / 2);
                    if (auxiliaryView) {
                        layout.auxiliaryViewFrame.origin.x = CGRectGetMaxX(layout.likeButtonFrame) + auxiliaryViewPadding;
                    }
                    break;
                }
                case FBLikeControlHorizontalAlignmentRight:{
                    layout.likeButtonFrame.origin.x = CGRectGetMaxX(bounds) - CGRectGetWidth(layout.likeButtonFrame);
                    if (auxiliaryView) {
                        layout.auxiliaryViewFrame.origin.x = CGRectGetMinX(layout.likeButtonFrame) - auxiliaryViewPadding - CGRectGetWidth(layout.auxiliaryViewFrame);
                    }
                    break;
                }
            }

            break;
        }
        case FBLikeControlAuxiliaryPositionTop:{
            if (auxiliaryView) {
                auxiliaryViewSize = CGSizeMake(CGRectGetWidth(bounds),
                                               CGRectGetHeight(bounds) - auxiliaryViewPadding - CGRectGetHeight(layout.likeButtonFrame));
                auxiliaryViewSize = subviewSizingBlock(auxiliaryView, auxiliaryViewSize);

                layout.auxiliaryViewFrame = CGRectMake(CGRectGetMinX(bounds),
                                                       CGRectGetMinY(bounds),
                                                       MAX(auxiliaryViewSize.width, CGRectGetWidth(layout.likeButtonFrame)),
                                                       auxiliaryViewSize.height);
            }
            layout.likeButtonFrame.origin.y = FBLikeControlPaddedDistance(CGRectGetMaxY(layout.auxiliaryViewFrame), auxiliaryViewPadding, YES);

            // calculate the size before offsetting the horizontal alignment, using the total calculated width
            layout.contentSize = FBLikeControlCalculateContentSize(layout);

            FBLikeControlApplyHorizontalAlignment(&layout.likeButtonFrame, bounds, self.likeControlHorizontalAlignment);
            FBLikeControlApplyHorizontalAlignment(&layout.auxiliaryViewFrame, bounds, self.likeControlHorizontalAlignment);
            break;
        }
        case FBLikeControlAuxiliaryPositionBottom:{
            if (auxiliaryView) {
                auxiliaryViewSize = CGSizeMake(CGRectGetWidth(bounds),
                                               CGRectGetHeight(bounds) - auxiliaryViewPadding - CGRectGetHeight(layout.likeButtonFrame));
                auxiliaryViewSize = subviewSizingBlock(auxiliaryView, auxiliaryViewSize);

                layout.auxiliaryViewFrame = CGRectMake(CGRectGetMinX(bounds),
                                                       CGRectGetMaxY(layout.likeButtonFrame) + auxiliaryViewPadding,
                                                       MAX(auxiliaryViewSize.width, CGRectGetWidth(layout.likeButtonFrame)),
                                                       auxiliaryViewSize.height);
            }

            // calculate the size before offsetting the horizontal alignment, using the total calculated width
            layout.contentSize = FBLikeControlCalculateContentSize(layout);

            FBLikeControlApplyHorizontalAlignment(&layout.likeButtonFrame, bounds, self.likeControlHorizontalAlignment);
            FBLikeControlApplyHorizontalAlignment(&layout.auxiliaryViewFrame, bounds, self.likeControlHorizontalAlignment);
            break;
        }
    }

    return layout;
}

- (void)_likeActionControllerDidResetNotification:(NSNotification *)notification
{
    [self _resetLikeActionController];
}

- (void)_resetLikeActionController
{
    [_likeActionController endContentAccess];
    [_likeActionController release];
    _likeActionController = [[FBLikeActionController likeActionControllerForObjectID:_objectID] retain];
}

- (void)_updateLikeBoxCaretPosition
{
    if (self.likeControlStyle != FBLikeControlStyleBoxCount) {
        return;
    }

    switch (self.likeControlAuxiliaryPosition) {
        case FBLikeControlAuxiliaryPositionInline:{
            switch (self.likeControlHorizontalAlignment) {
                case FBLikeControlHorizontalAlignmentLeft:
                case FBLikeControlHorizontalAlignmentCenter:{
                    _likeBoxView.caretPosition = FBLikeBoxCaretPositionLeft;
                    break;
                }
                case FBLikeControlHorizontalAlignmentRight:{
                    _likeBoxView.caretPosition = FBLikeBoxCaretPositionRight;
                    break;
                }
            }
            break;
        }
        case FBLikeControlAuxiliaryPositionTop:{
            _likeBoxView.caretPosition = FBLikeBoxCaretPositionBottom;
            break;
        }
        case FBLikeControlAuxiliaryPositionBottom:{
            _likeBoxView.caretPosition = FBLikeBoxCaretPositionTop;
            break;
        }
    }
}

@end
