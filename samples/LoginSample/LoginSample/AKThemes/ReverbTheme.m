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

#import "ReverbTheme.h"

@implementation ReverbTheme

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  ReverbTheme *copy = [super copyWithZone:zone];
  copy->_appIconImage = [_appIconImage copy];
  copy->_backArrowImage = [_backArrowImage copy];
  copy->_progressActiveColor = [_progressActiveColor copy];
  copy->_progressInactiveColor = [_progressInactiveColor copy];
  copy->_progressMode = _progressMode;
  copy->_textUppercase = _textUppercase;
  return copy;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  return [super hash] ^ [_appIconImage hash] ^ [_backArrowImage hash] ^ _textUppercase;
}

- (BOOL)isEqualToTheme:(AKFTheme *)theme
{
  ReverbTheme *reverbTheme = (ReverbTheme *)theme;
  return ([super isEqualToTheme:theme] &&
          [theme isKindOfClass:[ReverbTheme class]] &&
          (_progressMode == reverbTheme->_progressMode) &&
          (_textUppercase == reverbTheme->_textUppercase) &&
          ((_appIconImage == reverbTheme->_appIconImage) ||
           [_appIconImage isEqual:reverbTheme->_appIconImage]) &&
          ((_backArrowImage == reverbTheme->_backArrowImage) ||
           [_backArrowImage isEqual:reverbTheme->_backArrowImage]) &&
          ((_progressActiveColor == reverbTheme->_progressActiveColor) ||
           [_progressActiveColor isEqual:reverbTheme->_progressActiveColor]) &&
          ((_progressInactiveColor == reverbTheme->_progressInactiveColor) ||
           [_progressInactiveColor isEqual:reverbTheme->_progressInactiveColor]));
}

@end
