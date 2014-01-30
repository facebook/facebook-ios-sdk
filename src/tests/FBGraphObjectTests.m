/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBGraphObjectTests.h"
#import "FBGraphObject.h"
#import "FBGraphUser.h"
#import "FBGraphPlace.h"
#import "FBGraphLocation.h"
#import "FBTestBlocker.h"
#import "FBTests.h"

@protocol TestGraphProtocolTooManyArgs<FBGraphObject>
- (int)thisMethod:(int)has too:(int)many args:(int)yikes;
@end

@protocol TestGraphProtocolOptionalMethod<FBGraphObject>
@optional
- (NSString *)name;
@end

@protocol TestGraphProtocolVeryFewMethods<FBGraphObject>
@end

@protocol T1<FBGraphObject>
- (NSString *)name;
@end

@protocol T2
@end

@protocol TestGraphProtocolBoooBadLineage
- (NSString *)name;
@end

@protocol TestGraphProtocolBoooBadLineage2<TestGraphProtocolTooManyArgs>
- (NSString *)title;
@end

@protocol TestGraphProtocolGoodLineage3<T1, T2>
- (NSString *)title;
@end

@protocol TestGraphProtocolGoodLineage<TestGraphProtocolVeryFewMethods>
- (NSString *)title;
@end

@protocol TestGraphProtocolGoodLineage2<TestGraphProtocolVeryFewMethods, T1>
- (NSString *)title;
@end

@protocol NamedGraphObject<FBGraphObject>
@property (nonatomic, retain) NSString *name;
@end

@protocol NamedGraphObjectWithExtras<NamedGraphObject>
- (void)methodWithAnArg:(id)arg1 andAnotherArg:(id)arg2;
@end

@implementation FBGraphObjectTests

- (void)testCreateEmptyGraphObject {
    id<FBGraphObject> graphObject = [FBGraphObject graphObject];
    STAssertNotNil(graphObject, @"could not create FBGraphObject");
}

- (void)testCanSetProperty {
    id<NamedGraphObject> graphObject = (id<NamedGraphObject>)[FBGraphObject graphObject];
    [graphObject setName:@"A name"];
    assertThat([graphObject name], equalTo(@"A name"));
}

- (void)testRespondsToSelector {
    id<NamedGraphObject> graphObject = (id<NamedGraphObject>)[FBGraphObject graphObject];
    BOOL respondsToSelector = [graphObject respondsToSelector:@selector(setName:)];
    assertThatBool(respondsToSelector, equalToBool(YES));
}

- (void)testDoesNotHandleNonGetterSetter {
    @try {
        id<NamedGraphObjectWithExtras> graphObject = (id<NamedGraphObjectWithExtras>)[FBGraphObject graphObject];
        [graphObject methodWithAnArg:@"foo" andAnotherArg:@"bar"];
        STFail(@"should have gotten exception");
    } @catch (NSException *exception) {
    }
}

- (void)testCanRemoveObject {
    NSDictionary *initial = [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"value", @"key",
                             nil];
    NSMutableDictionary<FBGraphObject> *graphObject = [FBGraphObject graphObjectWrappingDictionary:initial];

    STAssertNotNil([graphObject objectForKey:@"key"], @"should have 'key'");

    [graphObject removeObjectForKey:@"key"];

    STAssertNil([graphObject objectForKey:@"key"], @"should not have 'key'");
}

- (void)testWrapWithGraphObject
{
    // construct a dictionary with an array and object as values
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSArray arrayWithObjects:@"one", [NSMutableDictionary dictionary], @"three", nil]
          forKey:@"array"];
    [d setObject:[NSMutableDictionary dictionary] forKey:@"object"];

    // make sure we got the object we expected when FBGraphObject-ifying it
    id obj = [FBGraphObject graphObjectWrappingDictionary:d];
    STAssertTrue([obj class] == [FBGraphObject class], @"Wrong class for resulting graph object");

    // make sure we don't double-wrap
    id obj2 = [FBGraphObject graphObjectWrappingDictionary:obj];
    STAssertTrue(obj == obj2, @"Different object implies faulty double-wrap");

    // use inferred implementation to fetch obj.array
    NSMutableArray *arr = [obj performSelector:@selector(array)];

    // did we get our array?
    STAssertTrue([arr isKindOfClass:[NSMutableArray class]], @"Wrong class for resulting graph object array");

    // make sure we don't double-wrap arrays
    obj2 = [FBGraphObject performSelector:@selector(graphObjectWrappingObject:) withObject:arr];
    STAssertTrue(arr == obj2, @"Different object implies faulty double-wrap");

    // is the first object the expected object?
    STAssertTrue([[arr objectAtIndex:0] isEqual:@"one"], @"Wrong array contents");

    // is the second index in the array wrapped?
    STAssertTrue([[arr objectAtIndex:1] class] == [FBGraphObject class], @"Wrong class for array element");

    // is the second object in the dictionary wrapped?
    STAssertTrue([[obj objectForKey:@"object"] class] == [FBGraphObject class], @"Wrong class for object item");

    // nil case?
    STAssertNil([FBGraphObject graphObjectWrappingDictionary:nil], @"Wrong result for nil wrapper");
}

- (void)testGraphObjectProtocolImplInference
{
    // get an object
    NSMutableDictionary *obj = [NSMutableDictionary dictionary];
    obj = [FBGraphObject graphObjectWrappingDictionary:obj];

    // assert its ability to be used with graph protocols (Note: new graph protocols should get a new line here
    STAssertTrue([obj conformsToProtocol:@protocol(FBGraphUser)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(FBGraphPlace)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(FBGraphLocation)], @"protocol inference is broken");

    // prove to ourselves we aren't always getting a yes
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolTooManyArgs)], @"protocol should not be inferrable");
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolOptionalMethod)], @"protocol should not be inferrable");
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolBoooBadLineage)], @"protocol should not be inferrable");
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolBoooBadLineage2)], @"protocol should not be inferrable");

    // some additional yes cases
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolGoodLineage)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolGoodLineage2)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolVeryFewMethods)], @"protocol should be inferrable");
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolGoodLineage3)], @"protocol should be inferrable");
}

- (void)testGraphObjectSameID
{
    NSString *anID = @"1234567890";

    id obj = [NSMutableDictionary dictionary];
    [obj setObject:anID forKey:@"id"];
    obj = [FBGraphObject graphObjectWrappingDictionary:obj];

    id objSameID = [NSMutableDictionary dictionary];
    [objSameID setObject:anID forKey:@"id"];
    objSameID = [FBGraphObject graphObjectWrappingDictionary:objSameID];

    id objDifferentID = [NSMutableDictionary dictionary];
    [objDifferentID setObject:@"999999" forKey:@"id"];
    objDifferentID = [FBGraphObject graphObjectWrappingDictionary:objDifferentID];

    id objNoID = [NSMutableDictionary dictionary];
    objNoID = [FBGraphObject graphObjectWrappingDictionary:objNoID];
    id objAnotherNoID = [NSMutableDictionary dictionary];
    objAnotherNoID = [FBGraphObject graphObjectWrappingDictionary:objAnotherNoID];

    STAssertTrue([FBGraphObject isGraphObjectID:obj sameAs:objSameID], @"same ID");
    STAssertTrue([FBGraphObject isGraphObjectID:obj sameAs:obj], @"same object");

    STAssertFalse([FBGraphObject isGraphObjectID:obj sameAs:objDifferentID], @"not same ID");

    // Objects with no ID should never match
    STAssertFalse([FBGraphObject isGraphObjectID:obj sameAs:objNoID], @"no ID");
    STAssertFalse([FBGraphObject isGraphObjectID:objNoID sameAs:obj], @"no ID");

    // Nil objects should never match an object with an ID
    STAssertFalse([FBGraphObject isGraphObjectID:obj sameAs:nil], @"nil object");
    STAssertFalse([FBGraphObject isGraphObjectID:nil sameAs:obj], @"nil object");

    // Having no ID is different than being a nil object
    STAssertFalse([FBGraphObject isGraphObjectID:objNoID sameAs:nil], @"nil object");

    // Two objects with no ID shouldn't match unless they are the same object.
    STAssertFalse([FBGraphObject isGraphObjectID:objNoID sameAs:objAnotherNoID], @"no IDs but different objects");
    STAssertTrue([FBGraphObject isGraphObjectID:objNoID sameAs:objNoID], @"no ID but same object");
}

- (id)graphObjectWithUnwrappedData
{
    NSDictionary *rawDictionary1 = [NSDictionary dictionaryWithObjectsAndKeys:@"world", @"hello", nil];
    NSDictionary *rawDictionary2 = [NSDictionary dictionaryWithObjectsAndKeys:@"world", @"bye", nil];
    NSArray *rawArray1 = [NSArray arrayWithObjects:@"anda1", @"anda2", @"anda3", nil];
    NSArray *rawArray2 = [NSArray arrayWithObjects:@"anda1", @"anda2", @"anda3", nil];

    NSDictionary *rawObject = [NSDictionary dictionaryWithObjectsAndKeys:
                               rawDictionary1, @"dict1",
                               rawDictionary2, @"dict2",
                               rawArray1, @"array1",
                               rawArray2, @"array2",
                               nil];
    NSDictionary<FBGraphObject> *graphObject = [FBGraphObject graphObjectWrappingDictionary:rawObject];

    return graphObject;
}

- (void)traverseGraphObject:(id)graphObject
{
    if ([graphObject isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in graphObject) {
            id value = [graphObject objectForKey:key];
            STAssertNotNil(value, @"missing value");
            [self traverseGraphObject:value];
        }
    } else if ([graphObject isKindOfClass:[NSArray class]]) {
        for (NSString *value in graphObject) {
            STAssertNotNil(value, @"missing value");
            [self traverseGraphObject:value];
        }
    }
}

- (void)testEnumeration
{
    id graphObject = [self graphObjectWithUnwrappedData];
    [self traverseGraphObject:graphObject];
}

- (void)testArrayObjectEnumerator
{
    NSMutableDictionary<FBGraphObject> *obj = [self createGraphObjectWithArray];
    NSMutableArray *array = [obj objectForKey:@"array"];

    NSEnumerator *enumerator = [array objectEnumerator];
    id o;
    int count = 0;
    while (o = [enumerator nextObject]) {
        assertThat(o, notNilValue());
        count++;
    }
    assertThatInt(count, equalToInt(3));
}

- (void)testArrayObjectReverseEnumerator
{
    NSMutableDictionary<FBGraphObject> *obj = [self createGraphObjectWithArray];
    NSMutableArray *array = [obj objectForKey:@"array"];

    NSEnumerator *enumerator = [array reverseObjectEnumerator];
    id o;
    int count = 0;
    while (o = [enumerator nextObject]) {
        assertThat(o, notNilValue());
        count++;
    }
    assertThatInt(count, equalToInt(3));
}

- (void)testInsertObjectAtIndex {
    NSMutableDictionary<FBGraphObject> *obj = [self createGraphObjectWithArray];
    NSMutableArray *array = [obj objectForKey:@"array"];
    [array insertObject:@"two" atIndex:1];

    assertThat([array objectAtIndex:1], equalTo(@"two"));

}

- (void)testRemoveObjectAtIndex {
    NSMutableDictionary<FBGraphObject> *obj = [self createGraphObjectWithArray];
    NSMutableArray *array = [obj objectForKey:@"array"];
    [array removeObjectAtIndex:1];

    assertThatInteger([array count], equalToInteger(2));
}

- (void)testAddObject {
    NSMutableDictionary<FBGraphObject> *obj = [self createGraphObjectWithArray];
    NSMutableArray *array = [obj objectForKey:@"array"];
    [array addObject:@"four"];

    assertThat([array objectAtIndex:3], equalTo(@"four"));
}

- (void)testRemoveLastObject {
    NSMutableDictionary<FBGraphObject> *obj = [self createGraphObjectWithArray];
    NSMutableArray *array = [obj objectForKey:@"array"];
    [array removeLastObject];

    assertThatInteger([array count], equalToInteger(2));
}

- (void)testReplaceObjectAtIndex {
    NSMutableDictionary<FBGraphObject> *obj = [self createGraphObjectWithArray];
    NSMutableArray *array = [obj objectForKey:@"array"];
    [array replaceObjectAtIndex:1 withObject:@"two"];

    assertThat([array objectAtIndex:1], equalTo(@"two"));
}

- (NSMutableDictionary<FBGraphObject> *)createGraphObjectWithArray {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSArray arrayWithObjects:@"one", [NSMutableDictionary dictionary], @"three", nil]
          forKey:@"array"];
    [d setObject:[NSMutableDictionary dictionary] forKey:@"object"];
    
    NSMutableDictionary<FBGraphObject> *obj = [FBGraphObject graphObjectWrappingDictionary:d];

    return obj;
}

@end
