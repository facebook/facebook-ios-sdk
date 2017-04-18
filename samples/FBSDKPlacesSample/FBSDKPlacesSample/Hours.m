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

#import "Hours.h"

@implementation Hours

+ (NSArray<Hours *> *)hourRangesForDictionary:(NSDictionary *)dictionary
{
  NSArray *days = @[@"sun", @"mon", @"tue", @"wed", @"thu", @"fri", @"sat"];

  NSMutableArray *hourRanges = [NSMutableArray new];

  for (NSInteger dayIndex = 0; dayIndex < 7; dayIndex++) {
    for (NSInteger rangeIndex = 1; rangeIndex <= 2; rangeIndex++) {
      NSString *rangeOpenKey = [NSString stringWithFormat:@"%@_%li_open", days[dayIndex], (long)rangeIndex];
      NSString *rangeCloseKey = [NSString stringWithFormat:@"%@_%li_close", days[dayIndex], (long)rangeIndex];
      if (dictionary[rangeOpenKey] && dictionary[rangeCloseKey]) {
        NSArray *openingTimeComponents = [dictionary[rangeOpenKey] componentsSeparatedByString:@":"];
        NSArray *closingTimeComponents = [dictionary[rangeCloseKey] componentsSeparatedByString:@":"];

        Hours *hours = [[Hours alloc] initWithWeekday:(dayIndex + 1)
                                          openingHour:[openingTimeComponents[0] integerValue]
                                        openingMinute:[openingTimeComponents[1] integerValue]
                                          closingHour:[closingTimeComponents[0] integerValue]
                                        closingMinute:[closingTimeComponents[1] integerValue]];
        [hourRanges addObject:hours];
      }
    }
  }
  return [hourRanges copy];
}

- (instancetype)initWithWeekday:(NSInteger)weekday
                    openingHour:(NSInteger)openingHour
                  openingMinute:(NSInteger)openingMinute
                    closingHour:(NSInteger)closingHour
                  closingMinute:(NSInteger)closingMinute
{
  self = [super init];
  if (self) {
    _openingTimeDateComponents = [NSDateComponents new];
    _closingTimeDateComponents = [NSDateComponents new];

    _openingTimeDateComponents.weekday = weekday;
    _openingTimeDateComponents.hour = openingHour;
    _openingTimeDateComponents.minute = openingMinute;

    _closingTimeDateComponents.weekday = weekday;
    _closingTimeDateComponents.hour = closingHour;
    _closingTimeDateComponents.minute = closingMinute;
  }
  return self;
}

- (NSString *)displayString
{
  NSArray *weekdays = [[NSCalendar currentCalendar] weekdaySymbols];

  return [NSString stringWithFormat:@"%@ %li:%02li-%li:%02li", weekdays[self.openingTimeDateComponents.weekday - 1], (long)self.openingTimeDateComponents.hour, (long)self.openingTimeDateComponents.minute, (long)self.closingTimeDateComponents.hour, (long)self.closingTimeDateComponents.minute];
}

@end
