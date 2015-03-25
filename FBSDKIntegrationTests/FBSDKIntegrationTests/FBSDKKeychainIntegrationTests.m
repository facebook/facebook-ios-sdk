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

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"

@interface FBSDKKeychainIntegrationTests : XCTestCase

@end

@implementation FBSDKKeychainIntegrationTests

- (void)testInitWithService
{
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    XCTAssertNotNil(store);
}

- (void)testInitWithServiceAndAccessGroup
{
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:@"TestGroup"];
    XCTAssertNotNil(store);
}

- (void)testReadFromEmptyStore
{
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    NSData *data = [store dataForKey:@"SomeKey"];
    XCTAssertNil(data);
}

- (void)testWriteToEmptyStore
{
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key" accessibility:NULL], @"Failed to write data to store");

    NSData *actual = [store dataForKey:@"key"];
    XCTAssertEqualObjects(expected, actual, @"Failed to read just stored data");
}

- (void)testWriteWithAccessability
{
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected
                          forKey:@"key"
                   accessibility:[FBSDKDynamicFrameworkLoader loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]], @"Failed to write data to store");

    NSData *actual = [store dataForKey:@"key"];
    XCTAssertEqualObjects(expected, actual, @"Failed to read just stored data");
}

- (void)testUpdateValue
{
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key" accessibility:NULL], @"Failed to write data to store");

    expected = [@"UpdatedTestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key" accessibility:NULL], @"Failed to update value in store");

    NSData *actual = [store dataForKey:@"key"];
    XCTAssertEqualObjects(expected, actual, @"Failed to read just stored data");
}

- (void)testDeleteValue
{
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    NSData *expected = [@"TestData" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([store setData:expected forKey:@"key" accessibility:NULL], @"Failed to write data to store");
    XCTAssertTrue([store setData:nil forKey:@"key" accessibility:NULL], @"Failed to update value in store");
    XCTAssertNil([store dataForKey:@"key"], @"Failed to delete value from store");
}

- (void)testReadString {
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    id mock = [OCMockObject partialMockForObject:store];

    [[mock expect] dataForKey:@"key"];

    [mock stringForKey:@"key"];
    [mock verify];
}

- (void)testReadDictionary {
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    id mock = [OCMockObject partialMockForObject:store];

    [[mock expect] dataForKey:@"key"];

    [mock dictionaryForKey:@"key"];
    [mock verify];
}

- (void)testWriteString {
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    id mock = [OCMockObject partialMockForObject:store];

    NSString *value = @"TestData";
    [[mock expect] setData:[OCMArg checkWithBlock:^BOOL(NSData * obj) {
        return [obj isEqualToData:[value dataUsingEncoding:NSUTF8StringEncoding]];
    }] forKey:@"key" accessibility:Nil];

    [(FBSDKKeychainStore *)mock setString:value forKey:@"key" accessibility:NULL];
    [mock verify];
}

- (void)testWriteDictionary {
    FBSDKKeychainStore *store = [[FBSDKKeychainStore alloc] initWithService:@"Test" accessGroup:nil];
    id mock = [OCMockObject partialMockForObject:store];

    NSDictionary *value = @{@"key1": @"Test", @1: @YES, @"key2": @1.0f};
    [[mock expect] setData:[OCMArg checkWithBlock:^BOOL(NSData * obj) {
        NSData *actual = [NSKeyedArchiver archivedDataWithRootObject:value];
        return [obj isEqualToData:actual];
    }] forKey:@"key" accessibility:Nil];

    [(FBSDKKeychainStore *)mock setDictionary:value forKey:@"key" accessibility:NULL];
    [mock verify];
}

@end
