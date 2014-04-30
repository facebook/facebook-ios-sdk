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

#import <UIKit/UIKit.h>

#import "FBSDKMacros.h"

/*!
 @abstract Insets a CGSize with the insets in a UIEdgeInsets.
 */
FBSDK_STATIC_INLINE CGSize FBEdgeInsetsInsetSize(CGSize size, UIEdgeInsets insets)
{
    CGRect rect = CGRectZero;
    rect.size = size;
    return UIEdgeInsetsInsetRect(rect, insets).size;
}

/*!
 @abstract Outsets a CGSize with the insets in a UIEdgeInsets.
 */
FBSDK_STATIC_INLINE CGSize FBEdgeInsetsOutsetSize(CGSize size, UIEdgeInsets insets)
{
    CGRect rect = CGRectZero;
    rect.size = size;
    return CGSizeMake(insets.left + size.width + insets.right,
                      insets.top + size.height + insets.bottom);
}

/*!
 @abstract Limits a CGFloat value, using the scale to limit to pixels (instead of points).

 @discussion The limitFunction is frequention floorf, ceilf or roundf.  If the scale is 2.0,
 you may get back values of *.5 to correspond to pixels.
 */
typedef float (*FBLimitFunctionType)(float);
FBSDK_STATIC_INLINE CGFloat FBPointsForScreenPixels(FBLimitFunctionType limitFunction, CGFloat screenScale, CGFloat pointValue)
{
    return limitFunction(pointValue * screenScale) / screenScale;
}

FBSDK_STATIC_INLINE CGSize FBTextSize(NSString *text, UIFont *font, CGSize constrainedSize, NSLineBreakMode lineBreakMode)
{
    CGSize size;
    if ([text respondsToSelector:@selector(sizeWithAttributes:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = lineBreakMode;
        size = [text sizeWithAttributes:@{
                                          NSFontAttributeName: font,
                                          NSParagraphStyleAttributeName: paragraphStyle,
                                          }];
        [paragraphStyle release];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        size = [text sizeWithFont:font constrainedToSize:constrainedSize lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}
