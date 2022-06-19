// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKMarketingKit/FBSDKMarketingKit.h>

#import "FeatureExtractor.h"
#import "ProductDetailViewController.h"

@interface CoffeeShopTests : XCTestCase

@end

@implementation CoffeeShopTests

- (void)setUp
{
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testViewHierarchyCaptureProductDetailPage
{
  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  UITabBarController *tab = [sb instantiateInitialViewController];
  ProductDetailViewController *detailVC = [sb instantiateViewControllerWithIdentifier:@"ProductDetailViewController"];
  [detailVC setSelectedProduct:[[Coffee getRandomCoffeeProducts:1] objectAtIndex:0]];
  [[UIApplication sharedApplication].delegate window].rootViewController = tab;
  UINavigationController *nav = (UINavigationController *)[tab selectedViewController];
  [nav pushViewController:detailVC animated:false];

  [nav view];
  [detailVC view];
  [[detailVC view] layoutIfNeeded];

  Class FBSDKCodelessIndexer = NSClassFromString(@"FBSDKCodelessIndexer");
  NSString *tree = [FBSDKCodelessIndexer performSelector:NSSelectorFromString(@"currentViewTree")];
  NSDictionary *treeInfo = [NSJSONSerialization JSONObjectWithData:[tree dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

  NSDictionary *uiTreeToTest = [[treeInfo objectForKey:@"view"] firstObject];

  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"uiTree" ofType:@"txt"];
  NSData *data = [NSData dataWithContentsOfFile:path];
  NSDictionary *uiTree = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

  XCTAssertTrue([self isUITreeEqual:uiTree toUITree:uiTreeToTest], @"UI Tree not equal");
}

// Compares all key and values, except dimension values because simulator device might be differen size
- (BOOL)isUITreeEqual:(NSDictionary *)tree1 toUITree:(NSDictionary *)tree2
{
  for (NSString *key in [tree1 allKeys]) {
    if ([key isEqualToString:@"dimension"]) {
      continue;
    }

    id value1 = tree1[key];
    id value2 = tree2[key];

    if ([value1 isKindOfClass:[NSArray class]]) {
      NSArray *array1 = (NSArray *)value1;
      NSArray *array2 = (NSArray *)value2;
      if ([array1 count] != [array2 count]) {
        return false;
      }
      for (int i = 0; i < [array1 count]; i++) {
        if (false == [self isUITreeEqual:[array1 objectAtIndex:i] toUITree:[array2 objectAtIndex:i]]) {
          return false;
        }
      }
    } else if ([value1 isKindOfClass:[NSDictionary class]]) {
      if (false == [self isUITreeEqual:value1 toUITree:value2]) {
        return false;
      }
    } else if (![value1 isEqual:value2]) {
      return false;
    }
  }
  return true;
}

- (void)testGetKeywordsFromText
{
  XCTAssertTrue(
    [[FeatureExtractor getKeywordsFrom:@"hello@World"]
     isEqualToString:@"hello World"]
  );
  XCTAssertTrue(
    [[FeatureExtractor getKeywordsFrom:@"helloWorldGoodbyeWorld"]
     isEqualToString:@"hello World Goodbye World"]
  );
  XCTAssertTrue(
    [[FeatureExtractor getKeywordsFrom:@"helloAWorldBGoodbyeCWorld"]
     isEqualToString:@"hello World Goodbye World"]
  );
  XCTAssertTrue(
    [[FeatureExtractor getKeywordsFrom:@"hello         World"]
     isEqualToString:@"hello World"]
  );
  XCTAssertTrue(
    [[FeatureExtractor getKeywordsFrom:@"hello  3.14159       World"]
     isEqualToString:@"hello World"]
  );
}

@end
