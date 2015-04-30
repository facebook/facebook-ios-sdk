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

#import "FBSDKMessengerButton.h"

#import "FBSDKMessengerUtils.h"

static const CGFloat kMessengerShareButtonCornerRadius = 5;

static const CGFloat kMessengerDefaultButtonWidthRect = 365;
static const CGFloat kMessengerButtonDefaultHeightRect = 45;

static const CGFloat kMessengerImageWidth = 23;
static const CGFloat kMessengerImageHeight = 45;

static const CGFloat kMessengerCircularButtonImageScaleRatio = .666;
static const CGFloat kMessengerCircularButtonDefaultSize = 75;

static const CGFloat kMessengerCircleBorderStrokeWidth = 1.0;

static const int kMessengerBlue = 0x0084FF;

static UIImage *DrawMessengerIcon(UIColor *color)
{
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(kMessengerImageWidth, kMessengerImageHeight), NO, 0);

  // Generated via http://www.paintcodeapp.com/
  UIBezierPath* messengerMarkPath = UIBezierPath.bezierPath;
  [messengerMarkPath moveToPoint:CGPointMake(8.5, 14.4)];
  [messengerMarkPath addCurveToPoint:CGPointMake(0, 22.3) controlPoint1: CGPointMake(3.8, 14.4) controlPoint2: CGPointMake(0, 18)];
  [messengerMarkPath addCurveToPoint:CGPointMake(3.2, 28.5) controlPoint1: CGPointMake(0, 24.8) controlPoint2: CGPointMake(1.2, 27)];
  [messengerMarkPath addLineToPoint:CGPointMake(3.2, 31.5)];
  [messengerMarkPath addLineToPoint:CGPointMake(6.1, 29.9)];
  [messengerMarkPath addCurveToPoint:CGPointMake(8.5, 30.2) controlPoint1: CGPointMake(6.9, 30.1) controlPoint2: CGPointMake(7.7, 30.2)];
  [messengerMarkPath addCurveToPoint:CGPointMake(17, 22.3) controlPoint1: CGPointMake(13.2, 30.2) controlPoint2: CGPointMake(17, 26.6)];
  [messengerMarkPath addCurveToPoint:CGPointMake(8.5, 14.4) controlPoint1: CGPointMake(17, 17.9) controlPoint2: CGPointMake(13.2, 14.4)];
  [messengerMarkPath closePath];
  [messengerMarkPath moveToPoint:CGPointMake(9.4, 25)];
  [messengerMarkPath addLineToPoint:CGPointMake(7.2, 22.7)];
  [messengerMarkPath addLineToPoint:CGPointMake(3, 25.1)];
  [messengerMarkPath addLineToPoint:CGPointMake(7.6, 20.2)];
  [messengerMarkPath addLineToPoint:CGPointMake(9.8, 22.5)];
  [messengerMarkPath addLineToPoint:CGPointMake(14, 20.2)];
  [messengerMarkPath addLineToPoint:CGPointMake(9.4, 25)];
  [messengerMarkPath closePath];
  messengerMarkPath.miterLimit = 4;
  [color setFill];
  [messengerMarkPath fill];

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

static CGFloat FBRoundPixelValueForScale(CGFloat f, CGFloat scale)
{
  // Round to the nearest device pixel (.5 on retina)
  return roundf(f * scale) / scale;
}


static CGFloat FBRoundPixelValue(CGFloat f)
{
  return FBRoundPixelValueForScale(f, [UIScreen mainScreen].scale);
}

static void DrawMessengerIconCircleLogo(UIColor *color, CGRect frame)
{
  CGSize size = CGSizeMake(FBRoundPixelValue(CGRectGetWidth(frame) * kMessengerCircularButtonImageScaleRatio),
                           FBRoundPixelValue(CGRectGetWidth(frame) * kMessengerCircularButtonImageScaleRatio));
  CGRect messengerMarkFrame = FBSDKMessengerRectMakeWithSizeCenteredInRect(size, frame);

  // Generated via http://www.paintcodeapp.com/
  UIBezierPath* messengerMarkVectorPath = UIBezierPath.bezierPath;
  [messengerMarkVectorPath moveToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.50000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.08000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addCurveToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.05000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.50000 * CGRectGetHeight(messengerMarkFrame)) controlPoint1: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.25000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.08000 * CGRectGetHeight(messengerMarkFrame)) controlPoint2: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.05000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.27000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addCurveToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.21500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.82500 * CGRectGetHeight(messengerMarkFrame)) controlPoint1: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.05000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.63000 * CGRectGetHeight(messengerMarkFrame)) controlPoint2: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.11500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.75000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.21500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.98500 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.37000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.90000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addCurveToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.50000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.92000 * CGRectGetHeight(messengerMarkFrame)) controlPoint1: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.41000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.91000 * CGRectGetHeight(messengerMarkFrame)) controlPoint2: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.45500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.92000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addCurveToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.95000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.50000 * CGRectGetHeight(messengerMarkFrame)) controlPoint1: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.75000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.92000 * CGRectGetHeight(messengerMarkFrame)) controlPoint2: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.95000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.73000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addCurveToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.50000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.08000 * CGRectGetHeight(messengerMarkFrame)) controlPoint1: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.95000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.27000 * CGRectGetHeight(messengerMarkFrame)) controlPoint2: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.75000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.08000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath closePath];
  [messengerMarkVectorPath moveToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.54500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.64500 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.43000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.52500 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.20500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.65000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.45000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.39000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.56500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.51000 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.79000 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.38500 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath addLineToPoint: CGPointMake(CGRectGetMinX(messengerMarkFrame) + 0.54500 * CGRectGetWidth(messengerMarkFrame), CGRectGetMinY(messengerMarkFrame) + 0.64500 * CGRectGetHeight(messengerMarkFrame))];
  [messengerMarkVectorPath closePath];
  messengerMarkVectorPath.miterLimit = 4;
  [color setFill];
  [messengerMarkVectorPath fill];
}

static void DrawMessengerIconCircleBackground(UIColor *fillColor, UIColor *borderColor, UIColor *logoColor, CGFloat width)
{
  // We offset the rect by one and reduce the width by 2 to prevent the border stroke from clipping
  UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(kMessengerCircleBorderStrokeWidth,
                                                                               kMessengerCircleBorderStrokeWidth,
                                                                               width - (2 * kMessengerCircleBorderStrokeWidth),
                                                                               width - (2 * kMessengerCircleBorderStrokeWidth))];

  [fillColor setFill];
  [bezierPath fill];

  if (borderColor) {
    [bezierPath setLineWidth:kMessengerCircleBorderStrokeWidth];
    [borderColor setStroke];
    [bezierPath stroke];
  }
}

static UIImage *DrawMessengerIconCircle(UIColor *fillColor, UIColor *borderColor, UIColor *logoColor, CGFloat width)
{
  CGRect messengerCircleFrame = CGRectMake(0, 0, FBRoundPixelValue(width), FBRoundPixelValue(width));
  UIGraphicsBeginImageContextWithOptions(messengerCircleFrame.size, NO, 0);

  DrawMessengerIconCircleBackground(fillColor, borderColor, logoColor, width);
  DrawMessengerIconCircleLogo(logoColor, messengerCircleFrame);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();
  return image;
}

static void UpdateRectangularButtonForStyle(UIButton *button, FBSDKMessengerShareButtonStyle style)
{
  UIImage *image = nil;
  switch (style) {
    case FBSDKMessengerShareButtonStyleBlue:
      button.backgroundColor = HEXColor(kMessengerBlue);
      [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
      button.tintColor = [UIColor whiteColor];
      image = DrawMessengerIcon([UIColor whiteColor]);
      break;
    case FBSDKMessengerShareButtonStyleWhite:
      button.backgroundColor = [UIColor whiteColor];
      [button setTitleColor:HEXColor(kMessengerBlue) forState:UIControlStateNormal];
      image = DrawMessengerIcon(HEXColor(kMessengerBlue));
      break;
    case FBSDKMessengerShareButtonStyleWhiteBordered:
      button.backgroundColor = [UIColor whiteColor];
      [button setTitleColor:HEXColor(kMessengerBlue) forState:UIControlStateNormal];
      button.layer.borderColor = HEXColor(kMessengerBlue).CGColor;
      button.layer.borderWidth = 1;
      image = DrawMessengerIcon(HEXColor(kMessengerBlue));
      break;
  }

  [button setImage:image forState:UIControlStateNormal];
}

static void UpdateCircularButtonForStyle(UIButton *button, FBSDKMessengerShareButtonStyle style, CGFloat width)
{
  UIImage *backgroundImage = nil;
  switch (style) {
    case FBSDKMessengerShareButtonStyleBlue:
      button.tintColor = [UIColor whiteColor];
      backgroundImage = DrawMessengerIconCircle(HEXColor(kMessengerBlue), nil, [UIColor whiteColor], width);
      break;
    case FBSDKMessengerShareButtonStyleWhite:
      button.backgroundColor = [UIColor clearColor];
      backgroundImage = DrawMessengerIconCircle([UIColor whiteColor], nil, HEXColor(kMessengerBlue), width);
      break;
    case FBSDKMessengerShareButtonStyleWhiteBordered:
      button.backgroundColor = [UIColor clearColor];
      backgroundImage = DrawMessengerIconCircle([UIColor whiteColor], HEXColor(kMessengerBlue), HEXColor(kMessengerBlue), width);
      break;
  }

  [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
}

@implementation FBSDKMessengerShareButton

#pragma mark - Public

+ (UIButton *)rectangularButtonWithStyle:(FBSDKMessengerShareButtonStyle)style;
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
  button.layer.cornerRadius = kMessengerShareButtonCornerRadius;
  button.frame = CGRectMake(0, 0, kMessengerDefaultButtonWidthRect, kMessengerButtonDefaultHeightRect);
  [button setTitle:NSLocalizedString(@"Send", @"Button label for sending a message") forState:UIControlStateNormal];
  UpdateRectangularButtonForStyle(button, style);

  return button;
}

+ (UIButton *)circularButtonWithStyle:(FBSDKMessengerShareButtonStyle)style width:(CGFloat)width
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.contentMode = UIViewContentModeScaleToFill;
  button.frame = CGRectMake(0, 0, width, width);
  UpdateCircularButtonForStyle(button, style, kMessengerCircularButtonDefaultSize);
  return button;
}

+ (UIButton *)circularButtonWithStyle:(FBSDKMessengerShareButtonStyle)style
{
  return [FBSDKMessengerShareButton circularButtonWithStyle:style width:kMessengerCircularButtonDefaultSize];
}

@end
