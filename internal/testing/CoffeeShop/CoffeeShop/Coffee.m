// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "Coffee.h"

#define COFFEE_NAME(x) [NSString stringWithFormat:@"Coffee %i", x]
#define COFFEE_DESC(x) [NSString stringWithFormat:@"Coffee %i has a crisp, bright flavor, with subtle hints of citrus and rich chocolates.", x]
#define COFFEE_PRICE 5.99
#define COFFEE_USERDATA @{@"em" : @"Test@FB.com ", @"ph" : @"+1-123(234556) ", @"fn" : @" App Signals"}

@implementation Coffee

@synthesize name = _name;
@synthesize desc = _desc;
@synthesize price = _price;
@synthesize userData = _userData;

- (instancetype)initWithName:(NSString *)name desc:(NSString *)desc price:(float)price userData:(NSDictionary *)userData
{
  if ((self = [super init])) {
    _name = [name copy];
    _desc = [desc copy];
    _price = price;
    _userData = [userData copy];
  }

  return self;
}

+ (NSArray *)getRandomCoffeeProducts:(int)numProducts
{
  NSMutableArray *coffeeProducts = [NSMutableArray array];

  for (int i = 0; i <= numProducts; i++) {
    Coffee *product = [[Coffee alloc] initWithName:COFFEE_NAME(i)
                                              desc:COFFEE_DESC(i)
                                             price:COFFEE_PRICE
                                          userData:COFFEE_USERDATA];
    [coffeeProducts addObject:product];
  }

  // Add product with sensitive data
  [coffeeProducts addObject:[[Coffee alloc] initWithName:@"Hello@fb.com"
                                                    desc:@"Hello"
                                                   price:10
                                                userData:COFFEE_USERDATA]];

  return coffeeProducts;
}

@end
