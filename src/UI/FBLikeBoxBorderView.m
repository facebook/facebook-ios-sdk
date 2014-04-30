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

#import "FBLikeBoxBorderView.h"

#import "FBColor.h"
#import "FBUIHelpers.h"

#define FBLikeBoxBorderCaretWidth 6.0
#define FBLikeBoxBorderCaretHeight 3.0
#define FBLikeBoxBorderCaretPadding 3.0
#define FBLikeBoxBorderContentPadding 4.0

@implementation FBLikeBoxBorderView

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
    [_contentView release];
    [_fillColor release];
    [_foregroundColor release];
    [super dealloc];
}

#pragma mark - Properties

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (![self.backgroundColor isEqual:backgroundColor]) {
        [super setBackgroundColor:backgroundColor];
        [self setNeedsDisplay];
    }
}

- (void)setBorderCornerRadius:(CGFloat)borderCornerRadius
{
    if (_borderCornerRadius != borderCornerRadius) {
        _borderCornerRadius = borderCornerRadius;
        [self setNeedsDisplay];
    }
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    if (_borderWidth != borderWidth) {
        _borderWidth = borderWidth;
        [self setNeedsDisplay];
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setCaretPosition:(FBLikeBoxCaretPosition)caretPosition
{
    if (_caretPosition != caretPosition) {
        _caretPosition = caretPosition;
        [self setNeedsLayout];
        [self setNeedsDisplay];
        [self invalidateIntrinsicContentSize];
    }
}

- (UIEdgeInsets)contentInsets
{
    UIEdgeInsets borderInsets = [self _borderInsets];
    return UIEdgeInsetsMake(borderInsets.top + FBLikeBoxBorderContentPadding,
                            borderInsets.left + FBLikeBoxBorderContentPadding,
                            borderInsets.bottom + FBLikeBoxBorderContentPadding,
                            borderInsets.right + FBLikeBoxBorderContentPadding);
}

- (void)setContentView:(UIView *)contentView
{
    if (_contentView != contentView) {
        [_contentView removeFromSuperview];
        [_contentView release];
        _contentView = [contentView retain];
        [self addSubview:_contentView];
        [self setNeedsLayout];
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setFillColor:(UIColor *)fillColor
{
    if (![_fillColor isEqual:fillColor]) {
        [_fillColor release];
        _fillColor = [fillColor retain];
        [self setNeedsDisplay];
    }
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    if (![_foregroundColor isEqual:foregroundColor]) {
        [_foregroundColor release];
        _foregroundColor = [foregroundColor retain];
        [self setNeedsDisplay];
    }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    return FBEdgeInsetsOutsetSize(self.contentView.intrinsicContentSize, self.contentInsets);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.contentView.frame = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    UIEdgeInsets contentInsets = self.contentInsets;
    size = FBEdgeInsetsInsetSize(size, contentInsets);
    size = [self.contentView sizeThatFits:size];
    size = FBEdgeInsetsOutsetSize(size, contentInsets);
    return size;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    // read the configuration properties
    CGRect bounds = self.bounds;
    CGFloat borderWidth = self.borderWidth;
    CGFloat borderCornerRadius = self.borderCornerRadius;
    CGFloat contentScaleFactor = self.contentScaleFactor;

    // fill the background
    if (self.backgroundColor) {
        [self.backgroundColor setFill];
        CGContextFillRect(context, bounds);
    }

    // configure the colors and lines
    [self.fillColor setFill];
    [self.foregroundColor setStroke];
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineWidth(context, borderWidth);

    // get the frame of the box
    CGRect borderFrame = UIEdgeInsetsInsetRect(bounds, [self _borderInsets]);

    // define the arcs for the corners
    const int start = 0;
    const int tangent = 1;
    const int end = 2;
    CGPoint topLeftArc[3] = {
        CGPointMake(CGRectGetMinX(borderFrame) + borderCornerRadius, CGRectGetMinY(borderFrame)),
        CGPointMake(CGRectGetMinX(borderFrame), CGRectGetMinY(borderFrame)),
        CGPointMake(CGRectGetMinX(borderFrame), CGRectGetMinY(borderFrame) + borderCornerRadius),
    };
    CGPoint bottomLeftArc[3] = {
        CGPointMake(CGRectGetMinX(borderFrame), CGRectGetMaxY(borderFrame) - borderCornerRadius),
        CGPointMake(CGRectGetMinX(borderFrame), CGRectGetMaxY(borderFrame)),
        CGPointMake(CGRectGetMinX(borderFrame) + borderCornerRadius, CGRectGetMaxY(borderFrame)),
    };
    CGPoint bottomRightArc[3] = {
        CGPointMake(CGRectGetMaxX(borderFrame) - borderCornerRadius, CGRectGetMaxY(borderFrame)),
        CGPointMake(CGRectGetMaxX(borderFrame), CGRectGetMaxY(borderFrame)),
        CGPointMake(CGRectGetMaxX(borderFrame), CGRectGetMaxY(borderFrame) - borderCornerRadius),
    };
    CGPoint topRightArc[3] = {
        CGPointMake(CGRectGetMaxX(borderFrame), CGRectGetMinY(borderFrame) + borderCornerRadius),
        CGPointMake(CGRectGetMaxX(borderFrame), CGRectGetMinY(borderFrame)),
        CGPointMake(CGRectGetMaxX(borderFrame) - borderCornerRadius, CGRectGetMinY(borderFrame)),
    };

    // start a path on the context
    CGContextBeginPath(context);

    // position the caret and decide which lines to draw
    CGPoint caretPoints[3];
    switch (self.caretPosition) {
        case FBLikeBoxCaretPositionTop:
            CGContextMoveToPoint(context, topRightArc[end].x, topRightArc[end].y);
            caretPoints[0] = CGPointMake(FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidX(borderFrame) + (FBLikeBoxBorderCaretWidth / 2)),
                                         CGRectGetMinY(borderFrame));
            caretPoints[1] = CGPointMake(FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidX(borderFrame)),
                                         CGRectGetMinY(borderFrame) - FBLikeBoxBorderCaretHeight);
            caretPoints[2] = CGPointMake(FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidX(borderFrame) - (FBLikeBoxBorderCaretWidth / 2)),
                                         CGRectGetMinY(borderFrame));
            CGContextAddLines(context, caretPoints, sizeof(caretPoints) / sizeof(caretPoints[0]));
            CGContextAddArcToPoint(context, topLeftArc[tangent].x, topLeftArc[tangent].y, topLeftArc[end].x, topLeftArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, bottomLeftArc[start].x, bottomLeftArc[start].y);
            CGContextAddArcToPoint(context, bottomLeftArc[tangent].x, bottomLeftArc[tangent].y, bottomLeftArc[end].x, bottomLeftArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, bottomRightArc[start].x, bottomRightArc[start].y);
            CGContextAddArcToPoint(context, bottomRightArc[tangent].x, bottomRightArc[tangent].y, bottomRightArc[end].x, bottomRightArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, topRightArc[start].x, topRightArc[start].y);
            CGContextAddArcToPoint(context, topRightArc[tangent].x, topRightArc[tangent].y, topRightArc[end].x, topRightArc[end].y, borderCornerRadius);
            break;
        case FBLikeBoxCaretPositionLeft:
            CGContextMoveToPoint(context, topLeftArc[end].x, topLeftArc[end].y);
            caretPoints[0] = CGPointMake(CGRectGetMinX(borderFrame),
                                         FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidY(borderFrame) - (FBLikeBoxBorderCaretWidth / 2)));
            caretPoints[1] = CGPointMake(CGRectGetMinX(borderFrame) - FBLikeBoxBorderCaretHeight,
                                         FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidY(borderFrame)));
            caretPoints[2] = CGPointMake(CGRectGetMinX(borderFrame),
                                         FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidY(borderFrame) + (FBLikeBoxBorderCaretWidth / 2)));
            CGContextAddLines(context, caretPoints, sizeof(caretPoints) / sizeof(caretPoints[0]));
            CGContextAddArcToPoint(context, bottomLeftArc[tangent].x, bottomLeftArc[tangent].y, bottomLeftArc[end].x, bottomLeftArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, bottomRightArc[start].x, bottomRightArc[start].y);
            CGContextAddArcToPoint(context, bottomRightArc[tangent].x, bottomRightArc[tangent].y, bottomRightArc[end].x, bottomRightArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, topRightArc[start].x, topRightArc[start].y);
            CGContextAddArcToPoint(context, topRightArc[tangent].x, topRightArc[tangent].y, topRightArc[end].x, topRightArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, topLeftArc[start].x, topLeftArc[start].y);
            CGContextAddArcToPoint(context, topLeftArc[tangent].x, topLeftArc[tangent].y, topLeftArc[end].x, topLeftArc[end].y, borderCornerRadius);
            break;
        case FBLikeBoxCaretPositionBottom:
            CGContextMoveToPoint(context, bottomLeftArc[end].x, bottomLeftArc[end].y);
            caretPoints[0] = CGPointMake(FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidX(borderFrame) - (FBLikeBoxBorderCaretWidth / 2)),
                                         CGRectGetMaxY(borderFrame));
            caretPoints[1] = CGPointMake(FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidX(borderFrame)),
                                         CGRectGetMaxY(borderFrame) + FBLikeBoxBorderCaretHeight);
            caretPoints[2] = CGPointMake(FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidX(borderFrame) + (FBLikeBoxBorderCaretWidth / 2)),
                                         CGRectGetMaxY(borderFrame));
            CGContextAddLines(context, caretPoints, sizeof(caretPoints) / sizeof(caretPoints[0]));
            CGContextAddArcToPoint(context, bottomRightArc[tangent].x, bottomRightArc[tangent].y, bottomRightArc[end].x, bottomRightArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, topRightArc[start].x, topRightArc[start].y);
            CGContextAddArcToPoint(context, topRightArc[tangent].x, topRightArc[tangent].y, topRightArc[end].x, topRightArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, topLeftArc[start].x, topLeftArc[start].y);
            CGContextAddArcToPoint(context, topLeftArc[tangent].x, topLeftArc[tangent].y, topLeftArc[end].x, topLeftArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, bottomLeftArc[start].x, bottomLeftArc[start].y);
            CGContextAddArcToPoint(context, bottomLeftArc[tangent].x, bottomLeftArc[tangent].y, bottomLeftArc[end].x, bottomLeftArc[end].y, borderCornerRadius);
            break;
        case FBLikeBoxCaretPositionRight:
            CGContextMoveToPoint(context, bottomRightArc[end].x, bottomRightArc[end].y);
            caretPoints[0] = CGPointMake(CGRectGetMaxX(borderFrame),
                                         FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidY(borderFrame) + (FBLikeBoxBorderCaretWidth / 2)));
            caretPoints[1] = CGPointMake(CGRectGetMaxX(borderFrame) + FBLikeBoxBorderCaretHeight,
                                         FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidY(borderFrame)));
            caretPoints[2] = CGPointMake(CGRectGetMaxX(borderFrame),
                                         FBPointsForScreenPixels(floorf, contentScaleFactor, CGRectGetMidY(borderFrame) - (FBLikeBoxBorderCaretWidth / 2)));
            CGContextAddLines(context, caretPoints, sizeof(caretPoints) / sizeof(caretPoints[0]));
            CGContextAddArcToPoint(context, topRightArc[tangent].x, topRightArc[tangent].y, topRightArc[end].x, topRightArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, topLeftArc[start].x, topLeftArc[start].y);
            CGContextAddArcToPoint(context, topLeftArc[tangent].x, topLeftArc[tangent].y, topLeftArc[end].x, topLeftArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, bottomLeftArc[start].x, bottomLeftArc[start].y);
            CGContextAddArcToPoint(context, bottomLeftArc[tangent].x, bottomLeftArc[tangent].y, bottomLeftArc[end].x, bottomLeftArc[end].y, borderCornerRadius);
            CGContextAddLineToPoint(context, bottomRightArc[start].x, bottomRightArc[start].y);
            CGContextAddArcToPoint(context, bottomRightArc[tangent].x, bottomRightArc[tangent].y, bottomRightArc[end].x, bottomRightArc[end].y, borderCornerRadius);
            break;
    }

    // close and draw now that we have it all
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);

    CGContextRestoreGState(context);
}

#pragma mark - Helper Methods

- (UIEdgeInsets)_borderInsets
{
    // inset the border bounds by 1/2 of the border width, since it is drawn split between inside and outside of the path
    CGFloat scale = self.contentScaleFactor;
    CGFloat halfBorderWidth = FBPointsForScreenPixels(ceilf, scale, self.borderWidth / 2);
    UIEdgeInsets borderInsets = UIEdgeInsetsMake(halfBorderWidth, halfBorderWidth, halfBorderWidth, halfBorderWidth);

    // adjust the insets for the caret position
    switch (self.caretPosition) {
        case FBLikeBoxCaretPositionTop:{
            borderInsets.top += FBLikeBoxBorderCaretHeight + FBLikeBoxBorderCaretPadding;
            break;
        }
        case FBLikeBoxCaretPositionLeft:{
            borderInsets.left += FBLikeBoxBorderCaretHeight + FBLikeBoxBorderCaretPadding;
            break;
        }
        case FBLikeBoxCaretPositionBottom:{
            borderInsets.bottom += FBLikeBoxBorderCaretHeight + FBLikeBoxBorderCaretPadding;
            break;
        }
        case FBLikeBoxCaretPositionRight:{
            borderInsets.right += FBLikeBoxBorderCaretHeight + FBLikeBoxBorderCaretPadding;
            break;
        }
    }

    return borderInsets;
}

- (void)_initializeContent
{
    self.backgroundColor = [UIColor clearColor];
    self.borderCornerRadius = 3.0;
    self.borderWidth = 1.0;
    self.contentMode = UIViewContentModeRedraw;
    self.fillColor = [UIColor whiteColor];
    self.foregroundColor = FBUIColorWithRGB(0x6A, 0x71, 0x80);
    self.opaque = NO;
}

@end
