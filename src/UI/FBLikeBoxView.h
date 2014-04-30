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

/*!
 @typedef NS_ENUM(NSUInteger, FBLikeBoxCaretPosition)

 @abstract Specifies the position of the caret relative to the box.
 */
typedef NS_ENUM(NSUInteger, FBLikeBoxCaretPosition)
{
    /*! The caret is on the top of the box. */
    FBLikeBoxCaretPositionTop,
    /*! The caret is on the left of the box. */
    FBLikeBoxCaretPositionLeft,
    /*! The caret is on the bottom of the box. */
    FBLikeBoxCaretPositionBottom,
    /*! The caret is on the right of the box. */
    FBLikeBoxCaretPositionRight,
};

@interface FBLikeBoxView : UIView

@property (nonatomic, assign) FBLikeBoxCaretPosition caretPosition;
@property (nonatomic, assign) NSUInteger likeCount;

- (void)setLikeCount:(NSUInteger)likeCount animated:(BOOL)animated;

@end
