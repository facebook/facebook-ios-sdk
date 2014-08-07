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

#import <XCTest/XCTest.h>

#import "FBDynamicFrameworkLoader.h"
#import "FBKeychainStore.h"
#import "FBTests.h"

@interface FBKeychainTests : FBTests

@end

@implementation FBKeychainTests

- (void)testInitWithService
{
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    XCTAssertNotNil(store);
}

- (void)testInitWithServiceAndAccessGroup
{
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test" accessGroup:@"TestGroup"] autorelease];
    XCTAssertNotNil(store);
}

- (void)testReadFromEmptyStore
{
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    NSData *data = [store dataForKey:@"SomeKey"];
    XCTAssertNil(data);
}

- (void)testWriteToEmptyStore
{
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key"], @"Failed to write data to store");

    NSData *actual = [store dataForKey:@"key"];
    XCTAssertEqualObjects(expected, actual, @"Failed to read just stored data");
}

- (void)testWriteWithAccessability
{
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected
                          forKey:@"key"
                   accessibility:[FBDynamicFrameworkLoader loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]], @"Failed to write data to store");

    NSData *actual = [store dataForKey:@"key"];
    XCTAssertEqualObjects(expected, actual, @"Failed to read just stored data");
}

- (void)testUpdateValue
{
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key"], @"Failed to write data to store");

    expected = [@"UpdatedTestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key"], @"Failed to update value in store");

    NSData *actual = [store dataForKey:@"key"];
    XCTAssertEqualObjects(expected, actual, @"Failed to read just stored data");
}

- (void)testDeleteValue
{
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key"], @"Failed to write data to store");
    XCTAssertTrue([store setData:nil forKey:@"key"], @"Failed to update value in store");
    XCTAssertNil([store dataForKey:@"key"], @"Failed to delete value from store");
}

- (void)testReadString {
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    id mock = [OCMockObject partialMockForObject:store];

    [[mock expect] dataForKey:@"key"];

    [mock stringForKey:@"key"];
    [mock verify];
}

- (void)testReadDictionary {
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    id mock = [OCMockObject partialMockForObject:store];

    [[mock expect] dataForKey:@"key"];

    [mock dictionaryForKey:@"key"];
    [mock verify];
}

- (void)testWriteString {
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    id mock = [OCMockObject partialMockForObject:store];

    NSString *value = @"TestData";
    [[mock expect] setData:[OCMArg checkWithBlock:^BOOL(NSData * obj) {
        return [obj isEqualToData:[value dataUsingEncoding:NSUTF8StringEncoding]];
    }] forKey:@"key" accessibility:Nil];

    [(FBKeychainStore *)mock setString:value forKey:@"key"];
    [mock verify];
}

- (void)testWriteDictionary {
    FBKeychainStore *store = [[[FBKeychainStore alloc] initWithService:@"Test"] autorelease];
    id mock = [OCMockObject partialMockForObject:store];

    NSDictionary *value = @{@"key1": @"Test", @1: @YES, @"key2": @1.0f};
    [[mock expect] setData:[OCMArg checkWithBlock:^BOOL(NSData * obj) {
        NSData *actual = [NSKeyedArchiver archivedDataWithRootObject:value];
        return [obj isEqualToData:actual];
    }] forKey:@"key" accessibility:Nil];

    [(FBKeychainStore *)mock setDictionary:value forKey:@"key"];
    [mock verify];
}

@end
