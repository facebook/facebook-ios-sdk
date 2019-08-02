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

@implementation FBSDKLibAnalyzer

+ (void)initialize
{
  [self generateMethodsTable];
}

#pragma mark - private methods

+ (void)generateMethodsTable
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSMutableArray<NSArray<NSString *> *> *methodMapping = [NSMutableArray array];
    NSArray<NSString *> *allClasses = [self getClassNames];
    for (NSString *className in allClasses) {
      Class class = NSClassFromString(className);
      [self addClass:class methodMappings:methodMapping isClassMethod:NO];
      [self addClass:object_getClass(class) methodMappings:methodMapping isClassMethod:YES];
    }
  });
}

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
  methodMappings:(NSMutableArray<NSArray<NSString *> *> *)methodMappings
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
      NSString *methodAddress = [NSString stringWithFormat:@"%lx", (unsigned long)methodImplementation];
      NSString *methodName = [NSString stringWithFormat:@"%@[%@ %@]",
                              methodType,
                              NSStringFromClass(class),
                              NSStringFromSelector(selector)];

      if (methodAddress && methodName) {
        NSArray<NSString *> *addressMapEntry = @[methodAddress, methodName];
        [methodMappings addObject:addressMapEntry];
      }
    }
  }
  free(methods);
}

@end
