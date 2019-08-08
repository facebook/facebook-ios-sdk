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

#import "FBSDKLibAnalyzer.h"

#import <objc/runtime.h>

#import "FBSDKCrashHandler.h"
#import "FBSDKCrashStorage.h"

@implementation FBSDKLibAnalyzer

static NSDictionary<NSString *,NSString *> *previousMapping;

+ (void)generateMethodsTable
{
    previousMapping = [FBSDKCrashStorage loadLibData];
    NSMutableDictionary<NSString *, NSString *> *methodMapping = [NSMutableDictionary dictionary];
    NSArray<NSString *> *allClasses = [self getClassNames];
    for (NSString *className in allClasses) {
      Class class = NSClassFromString(className);
      [self addClass:class methodMapping:methodMapping isClassMethod:NO];
      [self addClass:object_getClass(class) methodMapping:methodMapping isClassMethod:YES];
    }
    [FBSDKCrashStorage saveLibData:methodMapping];
}

#pragma mark - private methods

+(NSArray<NSString *> *)getClassNames
{
  unsigned int numClasses;
  Class *classes = objc_copyClassList(&numClasses);
  NSMutableArray<NSString *> *classNames = [NSMutableArray new];

  if (numClasses > 0) {
    NSString *className;
    Class singleClass = nil;
    for (int i = 0; i < numClasses; i++) {
      singleClass = classes[i];

      className = NSStringFromClass(singleClass);
      if ([className containsString:@"FBSDK"]) {
        [classNames addObject:className];
      }
    }
    free(classes);
  }

  return classNames;
}

+ (void)addClass:(Class)class
   methodMapping:(NSMutableDictionary<NSString *, NSString *> *)methodMapping
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
        [methodMapping setObject:methodName forKey:methodAddress];
      }
    }
  }
  free(methods);
}

+ (void)processCrashInfo:(NSDictionary<NSString *, id> *)crashInfo
                   block:(FBSDKCrashLoggerReportBlock)reportBlock
{
  if (crashInfo && reportBlock && previousMapping) {
    NSArray<NSString *> *sortedAllAddress = [previousMapping.allKeys sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
      return [obj1 compare:obj2];
    }];
    NSArray<NSString *> *callstack = crashInfo[kFBSDKCallstack];

    NSArray<NSString *> *symbolicatedCallstack = [self symbolicateCallstack:callstack sortedAllAddress:sortedAllAddress addressMapping:previousMapping];

    NSMutableDictionary<NSString *, id> *mutableCrashInfo = [NSMutableDictionary dictionaryWithDictionary:crashInfo];
    if (symbolicatedCallstack != nil) {
      mutableCrashInfo[kFBSDKCallstack] = symbolicatedCallstack;
      reportBlock(mutableCrashInfo);
    }
  }
}

+ (NSArray<NSString *> *)symbolicateCallstack:(NSArray<NSString *> *)callstack
                             sortedAllAddress:(NSArray<NSString *> *)sortedAllAddress
                               addressMapping:(NSDictionary<NSString *, NSString *> *)addressMapping
{
  if (!callstack){
    return nil;
  }
  NSMutableArray<NSString *> *symbolicatedCallstack = [NSMutableArray array];
  for (NSUInteger i = 0; i < callstack.count; i++){
    NSString *rawAddress = [self getAddress:callstack[i]];
    NSString *addressString = [NSString stringWithFormat:@"0x%@",[rawAddress substringWithRange:NSMakeRange(rawAddress.length - 10, 10)]];
    NSString *functionAddress = [self searchFunction:addressString sortedAllAddress:sortedAllAddress];
    if (functionAddress) {
      NSString *functionName = [addressMapping objectForKey:functionAddress];
      [symbolicatedCallstack addObject:[NSString stringWithFormat:@"%@", functionName]];
    }
  }
  return symbolicatedCallstack;
}

+ (NSString *)getAddress:(NSString *)callstackEntry
{
  NSArray<NSString *> *components = [callstackEntry componentsSeparatedByString:@" "];
  for (NSString *component in components) {
    if ([component containsString:@"0x"]) {
      return component;
    }
  }
  return nil;
}

+ (NSString *)searchFunction:(NSString *)address
            sortedAllAddress:(NSArray<NSString *> *)sortedAllAddress
{
  if (0 == sortedAllAddress.count)
  {
    return nil;
  }
  NSString *lowestAddress = sortedAllAddress[0];
  NSString *highestAddress = sortedAllAddress[sortedAllAddress.count - 1];

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
                                     usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                                       return [obj1 compare:obj2];
                                     }];
  return sortedAllAddress[index - 1];
}

@end
