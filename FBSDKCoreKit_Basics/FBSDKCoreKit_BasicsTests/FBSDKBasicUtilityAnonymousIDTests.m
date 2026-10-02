/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

static NSString *const kAnonymousIDFileName = @"com-facebook-sdk-PersistedAnonymousID.json";

@interface FBSDKBasicUtility (AnonymousIDTesting)

+ (void)persistNewAnonymousIDIfNeeded;

@end

@interface FBSDKBasicUtilityAnonymousIDTests : XCTestCase

@property (nonatomic, copy) NSString *filePath;

@end

@implementation FBSDKBasicUtilityAnonymousIDTests

- (void)setUp
{
  [super setUp];

  self.filePath = [FBSDKBasicUtility persistenceFilePath:kAnonymousIDFileName];
  [self removeAnonymousIDFile];
}

- (void)tearDown
{
  [self removeAnonymousIDFile];

  [super tearDown];
}

- (void)removeAnonymousIDFile
{
  [NSFileManager.defaultManager removeItemAtPath:self.filePath error:NULL];
}

- (void)writeFileContent:(NSString *)content
{
  [content writeToFile:self.filePath atomically:YES encoding:NSASCIIStringEncoding error:NULL];
}

- (nullable NSString *)fileContent
{
  return [NSString stringWithContentsOfFile:self.filePath encoding:NSASCIIStringEncoding error:NULL];
}

- (nullable NSString *)persistedAnonymousID
{
  NSData *data = [NSData dataWithContentsOfFile:self.filePath];
  if (!data) {
    return nil;
  }
  NSDictionary<NSString *, id> *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
  return json[@"anon_id"];
}

- (void)assertIsValidAnonymousID:(nullable NSString *)anonymousID
{
  XCTAssertTrue([anonymousID hasPrefix:@"XZ"], @"Anonymous IDs should be prefixed with XZ");
  XCTAssertNotNil(
    [[NSUUID alloc] initWithUUIDString:[anonymousID substringFromIndex:2]],
    @"Anonymous IDs should be an XZ prefixed UUID"
  );
}

// MARK: - Persisting a new anonymous ID

- (void)testPersistNewAnonymousIDIfNeededCreatesFileWhenMissing
{
  [FBSDKBasicUtility persistNewAnonymousIDIfNeeded];

  NSString *persisted = [self persistedAnonymousID];
  [self assertIsValidAnonymousID:persisted];
  XCTAssertEqualObjects(
    [FBSDKBasicUtility anonymousID],
    persisted,
    @"The anonymous ID should be the one persisted ahead of time"
  );
}

- (void)testPersistNewAnonymousIDIfNeededDoesNotOverwriteExistingFile
{
  [self writeFileContent:@"{\"anon_id\":\"XZ-EXISTING\"}"];

  [FBSDKBasicUtility persistNewAnonymousIDIfNeeded];

  XCTAssertEqualObjects([self persistedAnonymousID], @"XZ-EXISTING");
}

- (void)testPersistNewAnonymousIDIfNeededDoesNotOverwriteUnreadableFile
{
  [self writeFileContent:@"not json"];

  [FBSDKBasicUtility persistNewAnonymousIDIfNeeded];

  XCTAssertEqualObjects([self fileContent], @"not json");
}

- (void)testPersistedFileFormat
{
  [FBSDKBasicUtility persistNewAnonymousIDIfNeeded];

  NSString *anonymousID = [self persistedAnonymousID];
  XCTAssertEqualObjects(
    [self fileContent],
    ([NSString stringWithFormat:@"{\"anon_id\":\"%@\"}", anonymousID]),
    @"The file format must not change since other SDKs read the file directly"
  );
}

// MARK: - Reading the anonymous ID

- (void)testAnonymousIDCreatesAndPersistsIDWhenMissing
{
  NSString *anonymousID = [FBSDKBasicUtility anonymousID];

  [self assertIsValidAnonymousID:anonymousID];
  XCTAssertEqualObjects([self persistedAnonymousID], anonymousID);
  XCTAssertEqualObjects([FBSDKBasicUtility anonymousID], anonymousID, @"The anonymous ID should be stable");
}

- (void)testAnonymousIDReturnsPersistedID
{
  [self writeFileContent:@"{\"anon_id\":\"XZ-EXISTING\"}"];

  XCTAssertEqualObjects([FBSDKBasicUtility anonymousID], @"XZ-EXISTING");
}

- (void)testAnonymousIDReplacesUnreadableFile
{
  [self writeFileContent:@"not json"];

  NSString *anonymousID = [FBSDKBasicUtility anonymousID];

  [self assertIsValidAnonymousID:anonymousID];
  XCTAssertEqualObjects(
    [self persistedAnonymousID],
    anonymousID,
    @"A file that can't be read should be replaced with a newly minted ID"
  );
}

- (void)testConcurrentReadsOnFirstLaunchPersistASingleID
{
  NSMutableSet<NSString *> *anonymousIDs = [NSMutableSet set];
  NSLock *lock = [NSLock new];

  dispatch_apply(50, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^(size_t iteration) {
    if (iteration % 2 == 1) {
      [FBSDKBasicUtility persistNewAnonymousIDIfNeeded];
    }
    NSString *anonymousID = [FBSDKBasicUtility anonymousID];
    [lock lock];
    [anonymousIDs addObject:anonymousID];
    [lock unlock];
  });

  XCTAssertEqual(anonymousIDs.count, 1, @"Only one anonymous ID should ever be minted");
  XCTAssertEqualObjects(anonymousIDs.anyObject, [self persistedAnonymousID]);
}

@end
