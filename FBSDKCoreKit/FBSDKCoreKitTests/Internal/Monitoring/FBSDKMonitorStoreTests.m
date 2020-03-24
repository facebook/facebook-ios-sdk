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

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "FBSDKCoreKit+Internal.h"
#import "TestMonitorEntry.h"

@interface FBSDKMonitorStore (Testing)

- (void)clear;

@end

@interface FBSDKMonitorStoreTests : XCTestCase

@property (nonatomic, copy) NSString *filename;
@property (nonatomic) FBSDKMonitorStore *store;
@property (nonatomic) id<FBSDKMonitorEntry> entry;

@end

@implementation FBSDKMonitorStoreTests

- (void)setUp
{
  self.filename = @"foo";
  self.store = [[FBSDKMonitorStore alloc] initWithFilename:self.filename];
  self.entry = [TestMonitorEntry testEntry];
  [self clearStore];
}

- (void)tearDown
{
  self.store = nil;
  self.entry = nil;
}

- (void)testCreatingWithFilePath
{
  NSURL *temporaryDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
  NSURL *file = [temporaryDirectory URLByAppendingPathComponent:self.filename];

  XCTAssertEqualObjects(self.store.filePath, file,
                        @"Should store entries in the temporary directory");
}

- (void)testPersistingEmptyEntries
{
  [self.store persist:@[]];

  XCTAssertEqualObjects([self.store retrieveEntries], @[],
                        @"Should persist an empty list of entries");
}

- (void)testPersistingEntries
{
  NSArray<id<FBSDKMonitorEntry>> *expectedEntries = @[self.entry];

  [self.store persist:@[self.entry]];

  XCTAssertEqualObjects([self entriesFromDisk], expectedEntries,
                        @"Should persist entries correctly");
}

- (void)testPersistingDuplicateEntriesWithEmptyStore {
  TestMonitorEntry *entry2 = [TestMonitorEntry testEntry];
  NSArray *entries = @[self.entry, entry2];

  [self.store persist:entries];

  XCTAssertEqualObjects([self entriesFromDisk], entries,
                        @"Should allow persisting duplicate entries");
}

- (void)testPersistingDuplicateEntriesWithNonEmptyStore
{
  TestMonitorEntry *entry2 = [TestMonitorEntry testEntry];
  NSArray *entries = @[self.entry, entry2];

  [self.store persist:@[self.entry]];
  [self.store persist:entries];

  XCTAssertEqualObjects([self entriesFromDisk], entries,
                        @"Should overwrite any existing stored entries when persisting");
}

- (void)testPersistingUniqueEntriesWithEmptyStore
{
  TestMonitorEntry *entry2 = [TestMonitorEntry testEntryWithName:@"entry2"];
  NSArray<id<FBSDKMonitorEntry>> *entries = @[self.entry, entry2];

  [self.store persist:entries];

  XCTAssertEqualObjects([self entriesFromDisk], entries,
                        @"Should allow persisting unique entries");
}

- (void)testPersistingUniqueEntriesWithNonEmptyStore
{
  TestMonitorEntry *entry2 = [TestMonitorEntry testEntryWithName:@"entry2"];
  NSArray<id<FBSDKMonitorEntry>> *entries = @[self.entry, entry2];

  [self.store persist:@[self.entry]];
  [self.store persist:entries];

  XCTAssertEqualObjects([self entriesFromDisk], entries,
                        @"Should allow persisting unique entries");
}

- (void)testRetrievingWithoutPersistedEntries
{
  NSArray<id<FBSDKMonitorEntry>> *retrievedEntries = [self.store retrieveEntries];

  XCTAssertEqualObjects(retrievedEntries, @[],
                        @"Retrieving entries should return an empty array when no items are persisted");
}

- (void)testRetrievingClearsStore
{
  [self.store persist:@[self.entry]];
  [self.store retrieveEntries];

  NSArray<id<FBSDKMonitorEntry>> *retrieved = [self entriesFromDisk];

  XCTAssertNil(retrieved,
               @"Retrieving should clear existing entries");
}

- (void)testClearingStore {
  [self.store persist:@[self.entry]];

  [self.store clear];

  NSArray<id<FBSDKMonitorEntry>> *retrieved = [self entriesFromDisk];

  XCTAssertNil(retrieved,
               @"A cleared store should be empty");
}

// MARK: - Helpers

- (NSArray<id<FBSDKMonitorEntry>> *)entriesFromDisk
{
  NSURL *temporaryDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
  NSURL *file = [temporaryDirectory URLByAppendingPathComponent:self.filename];
  NSData *data = [NSData dataWithContentsOfURL:file];

  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)clearStore
{
  [[NSFileManager defaultManager] removeItemAtURL:self.store.filePath error:nil];
}

@end
