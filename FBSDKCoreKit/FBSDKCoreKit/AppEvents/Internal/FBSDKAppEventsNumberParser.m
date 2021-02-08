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

#import "FBSDKAppEventsNumberParser.h"

@implementation FBSDKAppEventsNumberParser
{
  NSLocale *_locale;
}

- (instancetype)initWithLocale:(NSLocale *)locale
{
  if ((self = [self init])) {
    _locale = locale;
  }
  return self;
}

- (NSNumber *)parseNumberFrom:(NSString *)string
{
  NSNumber *value = @0;

  NSString *ds = [_locale objectForKey:NSLocaleDecimalSeparator] ?: @".";
  NSString *gs = [_locale objectForKey:NSLocaleGroupingSeparator] ?: @",";
  NSString *separators = [ds stringByAppendingString:gs];

  NSString *regex = [NSString stringWithFormat:@"[+-]?([0-9]+[%1$@]?)?[%1$@]?([0-9]+[%1$@]?)+", separators];
  NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:regex
                                                                      options:0
                                                                        error:nil];
  NSTextCheckingResult *match = [re firstMatchInString:string
                                               options:0
                                                 range:NSMakeRange(0, string.length)];
  if (match) {
    NSString *validText = [string substringWithRange:match.range];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.locale = _locale;
    formatter.numberStyle = NSNumberFormatterDecimalStyle;

    value = [formatter numberFromString:validText];
    if (nil == value) {
      value = @(validText.floatValue);
    }
  }

  return value;
}

@end
