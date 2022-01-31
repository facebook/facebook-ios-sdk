/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLibAnalyzer.h"

#import <objc/runtime.h>

#import "FBSDKTypeUtility.h"

@implementation FBSDKLibAnalyzer

static NSMutableDictionary<NSString *, NSString *> *_methodMapping;

+ (void)initialize
{
  _methodMapping = [NSMutableDictionary dictionary];
}

+ (NSDictionary<NSString *, NSString *> *)getMethodsTable:(NSArray<NSString *> *)prefixes
                                               frameworks:(NSArray<NSString *> *)frameworks
{
  NSArray<NSString *> *allClasses = [self _getClassNames:prefixes frameworks:frameworks];
  for (NSString *className in allClasses) {
    Class class = NSClassFromString(className);
    if (class) {
      [self _addClass:class isClassMethod:NO];
      [self _addClass:object_getClass(class) isClassMethod:YES];
    }
  }
  @synchronized(_methodMapping) {
    return [_methodMapping copy];
  }
}

+ (nullable NSArray<NSString *> *)symbolicateCallstack:(NSArray<NSString *> *)callstack
                                         methodMapping:(NSDictionary<NSString *, id> *)methodMapping
{
  if (!callstack || !methodMapping) {
    return nil;
  }
  NSArray<NSString *> *sortedAllAddress = [methodMapping.allKeys sortedArrayUsingComparator:^NSComparisonResult (id _Nonnull obj1, id _Nonnull obj2) {
    return [obj1 compare:obj2];
  }];

  BOOL containsFBSDKFunction = NO;
  NSInteger nonSDKMethodCount = 0;
  NSMutableArray<NSString *> *symbolicatedCallstack = [NSMutableArray array];

  for (NSUInteger i = 0; i < callstack.count; i++) {
    NSString *rawAddress = [self _getAddress:[FBSDKTypeUtility array:callstack objectAtIndex:i]];
    if (rawAddress.length < 10) {
      continue;
    }
    NSString *addressString = [NSString stringWithFormat:@"0x%@", [rawAddress substringWithRange:NSMakeRange(rawAddress.length - 10, 10)]];
    NSString *methodAddress = [self _searchMethod:addressString sortedAllAddress:sortedAllAddress];

    if (methodAddress) {
      containsFBSDKFunction = YES;
      nonSDKMethodCount == 0 ?: [FBSDKTypeUtility array:symbolicatedCallstack addObject:[NSString stringWithFormat:@"(%ld DEV METHODS)", (long)nonSDKMethodCount]];
      nonSDKMethodCount = 0;
      NSString *methodName = [FBSDKTypeUtility dictionary:methodMapping objectForKey:methodAddress ofType:NSObject.class];

      // filter out cxx_destruct
      if ([methodName containsString:@".cxx_destruct"]) {
        return nil;
      }
      [FBSDKTypeUtility array:symbolicatedCallstack addObject:[NSString stringWithFormat:@"%@%@", methodName, [self _getOffset:addressString secondString:methodAddress]]];
    } else {
      nonSDKMethodCount++;
    }
  }
  nonSDKMethodCount == 0 ?: [FBSDKTypeUtility array:symbolicatedCallstack addObject:[NSString stringWithFormat:@"(%ld DEV METHODS)", (long)nonSDKMethodCount]];

  return containsFBSDKFunction ? symbolicatedCallstack : nil;
}

#pragma mark - Private Methods

+ (NSArray<NSString *> *)_getClassNames:(NSArray<NSString *> *)prefixes
                             frameworks:(NSArray<NSString *> *)frameworks
{
  NSMutableArray<NSString *> *classNames = [NSMutableArray new];
  // from main bundle
  [classNames addObjectsFromArray:[self _getClassesFrom:[NSBundle.mainBundle executablePath]
                                               prefixes:prefixes]];
  // from dynamic libraries
  if (frameworks.count > 0) {
    unsigned int count = 0;
    const char **images = objc_copyImageNames(&count);
    for (int i = 0; i < count; i++) {
      NSString *image = [NSString stringWithUTF8String:images[i]];
      for (NSString *framework in frameworks) {
        if ([image containsString:framework]) {
          [classNames addObjectsFromArray:[self _getClassesFrom:image
                                                       prefixes:nil]];
        }
      }
    }
    free(images);
  }

  return [classNames copy];
}

+ (NSArray<NSString *> *)_getClassesFrom:(NSString *)image
                                prefixes:(NSArray<NSString *> *)prefixes
{
  NSMutableArray<NSString *> *classNames = [NSMutableArray array];
  unsigned int count = 0;
  const char **classes = objc_copyClassNamesForImage([image UTF8String], &count);
  for (unsigned int i = 0; i < count; i++) {
    NSString *className = [NSString stringWithUTF8String:classes[i]];
    if (prefixes.count > 0) {
      for (NSString *prefix in prefixes) {
        if ([className hasPrefix:prefix]) {
          [FBSDKTypeUtility array:classNames addObject:className];
          break;
        }
      }
    } else {
      [FBSDKTypeUtility array:classNames addObject:className];
    }
  }
  free(classes);
  return [classNames copy];
}

+ (void)_addClass:(Class)class
    isClassMethod:(BOOL)isClassMethod
{
  unsigned int methodsCount = 0;
  Method *methods = class_copyMethodList(class, &methodsCount);

  NSString *methodType = isClassMethod ? @"+" : @"-";

  for (unsigned int i = 0; i < methodsCount; i++) {
    Method method = methods[i];

    if (method) {
      SEL selector = method_getName(method);

      IMP methodImplementation = class_getMethodImplementation(class, selector);
      NSString *methodAddress = [NSString stringWithFormat:@"0x%010lx", (unsigned long)methodImplementation];
      NSString *methodName = [NSString stringWithFormat:@"%@[%@ %@]",
                              methodType,
                              NSStringFromClass(class),
                              NSStringFromSelector(selector)];

      if (methodAddress && methodName) {
        @synchronized(_methodMapping) {
          [FBSDKTypeUtility dictionary:_methodMapping setObject:methodName forKey:methodAddress];
        }
      }
    }
  }
  free(methods);
}

+ (nullable NSString *)_getAddress:(nullable NSString *)callstackEntry
{
  if ([callstackEntry isKindOfClass:NSString.class]) {
    NSArray<NSString *> *components = [callstackEntry componentsSeparatedByString:@" "];
    for (NSString *component in components) {
      if ([component containsString:@"0x"]) {
        return component;
      }
    }
  }
  return nil;
}

+ (NSString *)_getOffset:(NSString *)firstString
            secondString:(NSString *)secondString
{
  unsigned long long first = 0, second = 0;
  NSScanner *scanner = [NSScanner scannerWithString:firstString];
  [scanner scanHexLongLong:&first];

  scanner = [NSScanner scannerWithString:secondString];
  [scanner scanHexLongLong:&second];

  unsigned long long difference = first - second;
  return [NSString stringWithFormat:@"+%llu", difference];
}

+ (nullable NSString *)_searchMethod:(NSString *)address
                    sortedAllAddress:(NSArray<NSString *> *)sortedAllAddress
{
  if (0 == sortedAllAddress.count) {
    return nil;
  }
  NSString *lowestAddress = sortedAllAddress.firstObject;
  NSString *highestAddress = [FBSDKTypeUtility array:sortedAllAddress objectAtIndex:sortedAllAddress.count - 1];

  if ([address compare:lowestAddress] == NSOrderedAscending || [address compare:highestAddress] == NSOrderedDescending) {
    return nil;
  }

  if ([address compare:lowestAddress] == NSOrderedSame) {
    return lowestAddress;
  }

  if ([address compare:highestAddress] == NSOrderedSame) {
    return highestAddress;
  }

  NSUInteger index = [sortedAllAddress indexOfObject:address
                                       inSortedRange:NSMakeRange(0, sortedAllAddress.count - 1)
                                             options:NSBinarySearchingInsertionIndex
                                     usingComparator:^NSComparisonResult (id _Nonnull obj1, id _Nonnull obj2) {
                                       return [obj1 compare:obj2];
                                     }];
  return [FBSDKTypeUtility array:sortedAllAddress objectAtIndex:index - 1];
}

@end
