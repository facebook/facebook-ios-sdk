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

#import <UIKit/UIKit.h>

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKIntegrationTestCase.h"

@interface FBSDKAccessTokenCache(FBSDKAccessTokenCacheIntegrationTests)

+ (void)resetV3CacheChecks;

@end

@interface FBSDKAccessTokenCacheIntegrationTests : FBSDKIntegrationTestCase

@end

@implementation FBSDKAccessTokenCacheIntegrationTests

- (void)XCODE8DISABLED_testCacheSimple {
  FBSDKAccessTokenCache *cache = [[FBSDKAccessTokenCache alloc] init];
  [cache clearCache];
  XCTAssertNil([cache fetchAccessToken], @"failed to clear cache");
  FBSDKAccessToken* token = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                              permissions:nil
                                                      declinedPermissions:nil
                                                                    appID:@"appid"
                                                                   userID:@"userid"
                                                           expirationDate:nil
                                                              refreshDate:nil];
  [cache cacheAccessToken:token];

  FBSDKAccessToken* retrievedToken = [cache fetchAccessToken];
  XCTAssertTrue([token isEqualToAccessToken:retrievedToken], @"did not retrieve the same token");
  [cache clearCache];
}

- (void)testV3CacheCompatibility {
#if IPHONE_SIMULATOR
  [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
#endif
  
  NSDictionary *tokenDictionary = @{
                                    @"com.facebook.sdk:TokenInformationTokenKey" : @"tokenString",
                                    @"com.facebook.sdk:TokenInformationPermissionsKey": @[ @"email"],
                                    @"com.facebook.sdk:TokenInformationExpirationDateKey": [[NSDate date] dateByAddingTimeInterval:-1],
                                    @"com.facebook.sdk:TokenInformationUserFBIDKey" : @"userid",
                                    @"com.facebook.sdk:TokenInformationDeclinedPermissionsKey" : @[ @"read_stream" ],
                                    @"com.facebook.sdk:TokenInformationAppIDKey" : [self testAppID],
                                    @"com.facebook.sdk:TokenInformationUUIDKey" : @"someuuid"
                                    };
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:tokenDictionary forKey:[FBSDKSettings legacyUserDefaultTokenInformationKeyName]];

  [FBSDKAccessTokenCache resetV3CacheChecks];
  FBSDKAccessTokenCache *cache = [[FBSDKAccessTokenCache alloc] init];
  FBSDKAccessToken* retrievedToken = [cache fetchAccessToken];
  XCTAssertNil(retrievedToken, @"should not have retrieved expired token");

  [cache clearCache];
}

- (void)XCODE8DISABLED_testV3_17CacheCompatibility {
  NSDictionary *tokenDictionary = @{
                                    @"com.facebook.sdk:TokenInformationTokenKey" : @"tokenString",
                                    @"com.facebook.sdk:TokenInformationPermissionsKey": @[ @"email"],
                                    @"com.facebook.sdk:TokenInformationUserFBIDKey" : @"userid",
                                    @"com.facebook.sdk:TokenInformationDeclinedPermissionsKey" : @[ @"read_stream" ],
                                    @"com.facebook.sdk:TokenInformationAppIDKey" : [self testAppID],
                                    @"com.facebook.sdk:TokenInformationUUIDKey" : @"someuuid"
                                    };
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *uuidKey = [[FBSDKSettings legacyUserDefaultTokenInformationKeyName] stringByAppendingString:@"UUID"];
  [defaults setObject:@"someuuid" forKey:uuidKey];

  FBSDKKeychainStoreViaBundleID *keyChainstore = [[FBSDKKeychainStoreViaBundleID alloc] init];
  [keyChainstore setDictionary:tokenDictionary forKey:[FBSDKSettings legacyUserDefaultTokenInformationKeyName] accessibility:nil];

  [FBSDKAccessTokenCache resetV3CacheChecks];
  FBSDKAccessTokenCache *cache = [[FBSDKAccessTokenCache alloc] init];
  FBSDKAccessToken* retrievedToken = [cache fetchAccessToken];
  XCTAssertNotNil(retrievedToken);
  XCTAssertEqualObjects(retrievedToken.tokenString, @"tokenString");
  XCTAssertEqualObjects(retrievedToken.permissions, [NSSet setWithObject:@"email"]);
  XCTAssertEqualObjects(retrievedToken.declinedPermissions, [NSSet setWithObject:@"read_stream"]);
  XCTAssertEqualObjects(retrievedToken.appID, [self testAppID]);
  XCTAssertEqualObjects(retrievedToken.userID, @"userid");

  [cache clearCache];
}

- (void)XCODE8DISABLED_testV3_21CacheCompatibility {
  NSDictionary *tokenDictionary = @{
                                    @"com.facebook.sdk:TokenInformationTokenKey" : @"tokenString",
                                    @"com.facebook.sdk:TokenInformationPermissionsKey": @[ @"email"],
                                    @"com.facebook.sdk:TokenInformationExpirationDateKey": [[NSDate date] dateByAddingTimeInterval:200],
                                    @"com.facebook.sdk:TokenInformationUserFBIDKey" : @"userid2",
                                    @"com.facebook.sdk:TokenInformationDeclinedPermissionsKey" : @[ @"read_stream" ],
                                    @"com.facebook.sdk:TokenInformationAppIDKey" : [self testAppID],
                                    @"com.facebook.sdk:TokenInformationUUIDKey" : @"someuuid"
                                    };
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *uuidKey = [[FBSDKSettings legacyUserDefaultTokenInformationKeyName] stringByAppendingString:@"UUID"];
  [defaults setObject:@"someuuid" forKey:uuidKey];

  NSString *keyChainServiceIdentifier = [NSString stringWithFormat:@"com.facebook.sdk.tokencache.%@", [[NSBundle mainBundle] bundleIdentifier]];
  FBSDKKeychainStore *keyChainstore = [[FBSDKKeychainStore alloc] initWithService:keyChainServiceIdentifier accessGroup:nil];
  [keyChainstore setDictionary:tokenDictionary forKey:[FBSDKSettings legacyUserDefaultTokenInformationKeyName] accessibility:nil];

  [FBSDKAccessTokenCache resetV3CacheChecks];
  FBSDKAccessTokenCache *cache = [[FBSDKAccessTokenCache alloc] init];
  FBSDKAccessToken* retrievedToken = [cache fetchAccessToken];
  XCTAssertNotNil(retrievedToken);
  XCTAssertEqualObjects(retrievedToken.tokenString, @"tokenString");
  XCTAssertEqualObjects(retrievedToken.permissions, [NSSet setWithObject:@"email"]);
  XCTAssertEqualObjects(retrievedToken.declinedPermissions, [NSSet setWithObject:@"read_stream"]);
  XCTAssertEqualObjects(retrievedToken.appID, [self testAppID]);
  XCTAssertEqualObjects(retrievedToken.userID, @"userid2");

  [cache clearCache];
}

@end
