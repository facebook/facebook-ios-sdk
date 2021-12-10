/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import "FBSDKSwizzler.h"
#import "FBSDKSwizzler+Testing.h"

@interface FBSDKSwizzlerTestObject : NSObject

@property (nonatomic) int methodToSwizzleAsynchronouslyCallCount;
@property (nonatomic) int methodWithNoArgumentsCallCount;
@property (nonatomic) int methodWithOneArgumentCallCount;
@property (nonatomic) int methodWithTwoArgumentsCallCount;
@property (nonatomic) int methodWithThreeArgumentsCallCount;
@property (nonatomic) int methodWithFourArgumentsCallCount;
@property (nonatomic) int methodToUnswizzleCallCount;
@property (nonatomic) int methodToConflictCallCount;
@property (nonatomic) int methodToOverrideCallCount;
@property (nonatomic) int methodToSwizzleInSuperAndSubclassCallCount;

- (void)methodToSwizzleAsynchronously;
- (void)methodWithNoArguments;
- (void)methodWithOneArgument:(id)arg;
- (void)methodWithArgument:(id)arg
            secondArgument:(id)arg2;
- (void)methodWithArgument:(id)arg
            secondArgument:(id)arg2
             thirdArgument:(id)arg3;
- (void)methodWithArgument:(id)arg
            secondArgument:(id)arg2
             thirdArgument:(id)arg3
            fourthArgument:(id)arg4;
- (void)methodToUnswizzle;
- (void)methodToConflict;
- (void)methodToOverride;
- (void)methodToSwizzleInSuperAndSubclass;

@end

@implementation FBSDKSwizzlerTestObject

- (instancetype)init
{
  if ((self = [super init])) {
    _methodToSwizzleAsynchronouslyCallCount = 0;
    _methodWithNoArgumentsCallCount = 0;
    _methodWithOneArgumentCallCount = 0;
    _methodWithTwoArgumentsCallCount = 0;
    _methodWithThreeArgumentsCallCount = 0;
    _methodWithFourArgumentsCallCount = 0;
    _methodToUnswizzleCallCount = 0;
    _methodToConflictCallCount = 0;
    _methodToOverrideCallCount = 0;
  }
  return self;
}

- (void)methodToSwizzleAsynchronously
{
  self.methodToSwizzleAsynchronouslyCallCount++;
}

- (void)methodWithNoArguments
{
  self.methodWithNoArgumentsCallCount++;
}

- (void)methodWithOneArgument:(id)arg
{
  self.methodWithOneArgumentCallCount++;
}

- (void)methodWithArgument:(id)arg
            secondArgument:(id)arg2
{
  self.methodWithTwoArgumentsCallCount++;
}

- (void)methodWithArgument:(id)arg
            secondArgument:(id)arg2
             thirdArgument:(id)arg3
{
  self.methodWithThreeArgumentsCallCount++;
}

- (void)methodWithArgument:(id)arg
            secondArgument:(id)arg2
             thirdArgument:(id)arg3
            fourthArgument:(id)arg4
{
  self.methodWithFourArgumentsCallCount++;
}

- (void)methodToUnswizzle
{
  self.methodToUnswizzleCallCount++;
}

- (void)methodToConflict
{
  self.methodToConflictCallCount++;
}

- (void)methodToOverride
{
  self.methodToOverrideCallCount++;
}

- (void)methodToSwizzleInSuperAndSubclass
{
  self.methodToSwizzleInSuperAndSubclassCallCount++;
}

@end

@interface FBSDKSwizzlerTestObjectSubclass : FBSDKSwizzlerTestObject
@end

@implementation FBSDKSwizzlerTestObjectSubclass

- (void)methodToOverride
{
  [super methodToOverride];
}

- (void)methodToSwizzleInSuperAndSubclass
{
  self.methodToSwizzleInSuperAndSubclassCallCount++;
  [super methodToSwizzleInSuperAndSubclass];
}

@end

@interface FBSDKSwizzlerTests : XCTestCase
@end

@implementation FBSDKSwizzlerTests

- (void)_testSwizzlingIsAsynchronousByDefault
{
  __block int swizzleBlockInvocationCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodToSwizzleAsynchronously)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         swizzleBlockInvocationCount++;
                       }
                           named:self.name];
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodToSwizzleAsynchronously];
  XCTAssertEqual(
    swizzleBlockInvocationCount,
    0,
    "Should not swizzle the method synchronously"
  );
  XCTAssertEqual(
    testObject.methodToSwizzleAsynchronouslyCallCount,
    1,
    "Should invoke the original implementation once per method call"
  );

  // Predicates expectations are evaluated every second so we can just poll
  // the method until it has been swizzled asynchronously
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary<NSString *, id> *bindings) {
    [testObject methodToSwizzleAsynchronously];
    return swizzleBlockInvocationCount > 0;
  }];

  XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
  [self waitForExpectations:@[expectation] timeout:3];
}

- (void)testSwizzlingMethodWithNoArguments
{
  __block int swizzleBlockInvocationCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodWithNoArguments)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         swizzleBlockInvocationCount++;
                       }
                           named:self.name
                           async:NO];
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodWithNoArguments];
  [testObject methodWithNoArguments];
  XCTAssertEqual(
    swizzleBlockInvocationCount,
    2,
    "Should invoke the swizzle block once per method call"
  );
  XCTAssertEqual(
    testObject.methodWithNoArgumentsCallCount,
    2,
    "Should invoke the original implementation once per method call"
  );
}

- (void)testSwizzlingMethodWithOneArgument
{
  __block int swizzleBlockInvocationCount = 0;
  __block id capturedArgument = nil;
  [FBSDKSwizzler swizzleSelector:@selector(methodWithOneArgument:)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^(id caller, SEL command, id arg) {
                         swizzleBlockInvocationCount++;
                         capturedArgument = arg;
                       }
                           named:self.name
                           async:NO];
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodWithOneArgument:@"Foo"];
  XCTAssertEqualObjects(
    capturedArgument,
    @"Foo",
    "Should invoke the swizzle block with the original arguments"
  );
  XCTAssertEqual(
    testObject.methodWithOneArgumentCallCount,
    1,
    "Should invoke the original implementation"
  );
  XCTAssertEqual(
    swizzleBlockInvocationCount,
    1,
    "Should invoke the swizzle block once per method call"
  );
}

- (void)testSwizzlingMethodWithTwoArguments
{
  __block id capturedArg1 = nil;
  __block id capturedArg2 = nil;
  __block int swizzleBlockInvocationCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodWithArgument:secondArgument:)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^(id caller, SEL command, id arg1, id arg2) {
                         capturedArg1 = arg1;
                         capturedArg2 = arg2;
                         swizzleBlockInvocationCount++;
                       }
                           named:self.name
                           async:NO];
  NSString *arg1 = @"Foo";
  NSString *arg2 = @"Bar";
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodWithArgument:arg1
                  secondArgument:arg2];
  XCTAssertEqualObjects(capturedArg1, arg1);
  XCTAssertEqualObjects(capturedArg2, arg2);
  XCTAssertEqual(
    testObject.methodWithTwoArgumentsCallCount,
    1,
    "Should invoke the original implementation"
  );
  XCTAssertEqual(
    swizzleBlockInvocationCount,
    1,
    "Should invoke the swizzle block once per method call"
  );
}

- (void)testSwizzlingMethodWithMaxAllowedArguments
{
  __block id capturedArg1 = nil;
  __block id capturedArg2 = nil;
  __block id capturedArg3 = nil;
  __block int swizzleBlockInvocationCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodWithArgument:secondArgument:thirdArgument:)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^(id caller, SEL command, id arg1, id arg2, id arg3) {
                         capturedArg1 = arg1;
                         capturedArg2 = arg2;
                         capturedArg3 = arg3;
                         swizzleBlockInvocationCount++;
                       }
                           named:self.name
                           async:NO];
  NSString *arg1 = @"Foo";
  NSString *arg2 = @"Bar";
  NSString *arg3 = @"Baz";
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodWithArgument:arg1
                  secondArgument:arg2
                   thirdArgument:arg3];
  XCTAssertEqualObjects(capturedArg1, arg1);
  XCTAssertEqualObjects(capturedArg2, arg2);
  XCTAssertEqualObjects(capturedArg3, arg3);
  XCTAssertEqual(
    testObject.methodWithThreeArgumentsCallCount,
    1,
    "Should invoke the original implementation"
  );
  XCTAssertEqual(
    swizzleBlockInvocationCount,
    1,
    "Should invoke the swizzle block once per method call"
  );
}

- (void)testSwizzlingMethodWithMoreThanMaxAllowedArguments
{
  __block BOOL didInvokeSwizzleBlock = NO;
  [FBSDKSwizzler swizzleSelector:@selector(methodWithArgument:secondArgument:thirdArgument:fourthArgument:) // fifthArgument:)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^(id caller, SEL command, id arg1, id arg2, id arg3, id arg4) {
                         didInvokeSwizzleBlock = YES;
                       }
                           named:self.name
                           async:NO];
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodWithArgument:@"Foo"
                  secondArgument:@"Foo"
                   thirdArgument:@"Foo"
                  fourthArgument:@"Foo"];
  XCTAssertFalse(
    didInvokeSwizzleBlock,
    "Should not invoke the swizzle block if there are too many arguments"
  );
  XCTAssertEqual(
    testObject.methodWithFourArgumentsCallCount,
    1,
    "Should invoke the original implementation"
  );
}

- (void)testSwizzlingWithNoName
{
  __block BOOL swizzleBlockWasCalled = NO;
  [FBSDKSwizzler swizzleSelector:@selector(methodWithNoArguments)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         swizzleBlockWasCalled = YES;
                       }
                           named:nil
                           async:NO];
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodWithNoArguments];
  XCTAssertFalse(
    swizzleBlockWasCalled,
    "Should not invoke the swizzle block for an unnamed swizzle"
  );
  XCTAssertEqual(
    testObject.methodWithNoArgumentsCallCount,
    1,
    "Should invoke the original implementation once per method call"
  );
}

- (void)testUnswizzling
{
  __block BOOL swizzleBlockWasCalled = NO;
  [FBSDKSwizzler swizzleSelector:@selector(methodToUnswizzle)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         swizzleBlockWasCalled = YES;
                       }
                           named:self.name
                           async:NO];
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodToUnswizzle];
  XCTAssertTrue(swizzleBlockWasCalled);

  // Reset the expectation
  swizzleBlockWasCalled = NO;

  [FBSDKSwizzler unswizzleSelector:@selector(methodToUnswizzle)
                           onClass:FBSDKSwizzlerTestObject.class
                             named:self.name];

  [testObject methodToUnswizzle];
  XCTAssertFalse(
    swizzleBlockWasCalled,
    "Should not invoke the swizzle block after the method has been unswizzled"
  );
  XCTAssertEqual(
    testObject.methodToUnswizzleCallCount,
    2,
    "Should invoke the original implementation once per method call"
  );
}

- (void)testConflictingSwizzles
{
  __block int swizzleBlockInvocationCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodToConflict)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         XCTFail("Should not call the overridden swizzle block");
                       }
                           named:self.name
                           async:NO];
  [FBSDKSwizzler swizzleSelector:@selector(methodToConflict)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         swizzleBlockInvocationCount++;
                       }
                           named:self.name
                           async:NO];
  FBSDKSwizzlerTestObject *testObject = [FBSDKSwizzlerTestObject new];
  [testObject methodToConflict];
  XCTAssertEqual(
    swizzleBlockInvocationCount,
    1,
    "Should override the first swizzle block with the subsequent swizzle block"
  );
  XCTAssertEqual(
    testObject.methodToConflictCallCount,
    1,
    "Should invoke the original implementation once per method call"
  );
}

- (void)testSwizzlingSubclass
{
  __block int swizzleBlockInvocationCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodToOverride)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         swizzleBlockInvocationCount++;
                       }
                           named:self.name
                           async:NO];
  FBSDKSwizzlerTestObjectSubclass *testObject = [FBSDKSwizzlerTestObjectSubclass new];
  [testObject methodToOverride];

  XCTAssertEqual(
    swizzleBlockInvocationCount,
    1,
    "Should find the swizzle on the superclass"
  );
}

- (void)testSwizzlingWhenBothSubAndSuperclassAreSwizzled
{
  // Swizzle the superclass
  __block int firstSwizzleBlockCallCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodToSwizzleInSuperAndSubclass)
                         onClass:FBSDKSwizzlerTestObject.class
                       withBlock:^{
                         firstSwizzleBlockCallCount++;
                       }
                           named:self.name
                           async:NO];
  // Swizzle the same method on the subclass
  __block int secondSwizzleBlockCallCount = 0;
  [FBSDKSwizzler swizzleSelector:@selector(methodToSwizzleInSuperAndSubclass)
                         onClass:FBSDKSwizzlerTestObjectSubclass.class
                       withBlock:^{
                         secondSwizzleBlockCallCount++;
                       }
                           named:self.name
                           async:NO];
  FBSDKSwizzlerTestObjectSubclass *testObject = [FBSDKSwizzlerTestObjectSubclass new];
  [testObject methodToSwizzleInSuperAndSubclass];

  XCTAssertEqual(
    firstSwizzleBlockCallCount,
    1,
    "Should call the swizzle block on the superclass"
  );
  XCTAssertEqual(
    secondSwizzleBlockCallCount,
    1,
    "Should call the swizzle block on the subclass"
  );
  XCTAssertEqual(
    testObject.methodToSwizzleInSuperAndSubclassCallCount,
    2,
    "Should call the original method on the superclass and subclass"
  );
}

@end
