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

#import "FBColor.h"

static const CGFloat kFBRGBMax = 255.0;

UIColor *FBUIColorWithRGBA(uint8_t r, uint8_t g, uint8_t b, CGFloat a)
{
    return [UIColor colorWithRed:(r / kFBRGBMax) green:(g / kFBRGBMax) blue:(b / kFBRGBMax) alpha:a];
}

UIColor *FBUIColorWithRGB(uint8_t r, uint8_t g, uint8_t b)
{
    return FBUIColorWithRGBA(r, g, b, 1.0);
}
