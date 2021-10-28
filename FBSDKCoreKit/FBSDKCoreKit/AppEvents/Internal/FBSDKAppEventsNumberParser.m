/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsNumberParser.h"

@interface FBSDKAppEventsNumberParser ()

@property (nonatomic) NSLocale *locale;

@end

@implementation FBSDKAppEventsNumberParser

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
