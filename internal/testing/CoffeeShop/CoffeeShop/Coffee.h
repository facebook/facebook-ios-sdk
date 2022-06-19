// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

@interface Coffee : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, assign) float price;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *userData;

- (instancetype)initWithName:(NSString *)name desc:(NSString *)desc price:(float)price userData:(NSDictionary *)userData;

+ (NSArray *)getRandomCoffeeProducts:(int)numProducts;

@end
