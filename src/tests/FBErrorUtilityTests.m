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

#import "FBAppCall+Internal.h"
#import "FBError.h"
#import "FBErrorUtility+Internal.h"
#import "FBSession+Internal.h"
#import "FBSessionAuthLogger.h"
#import "FBTests.h"

@interface FBErrorUtilityTests : FBTests
@end

@implementation FBErrorUtilityTests

- (void) testErrorCodeForError {
    NSDictionary *errorUserInfo = @{
                                    FBErrorParsedJSONResponseKey : @{
                                            @"body" : @{
                                                    @"error" : @{
                                                            // no error code or subcode present
                                                            }
                                                    }
                                            }
                                    };
    NSError *error = [NSError errorWithDomain:@"foo" code:3 userInfo:errorUserInfo];

    XCTAssertEqual(NSNotFound, [FBErrorUtility errorCodeForError:error]);
    XCTAssertEqual(NSNotFound, [FBErrorUtility errorSubcodeForError:error]);

    errorUserInfo = @{
                      FBErrorParsedJSONResponseKey : @{
                              @"body" : @{
                                      @"error" : @{
                                              @"code": @(451),
                                              @"error_subcode" : @(452)
                                              }
                                      }
                              }
                      };
    error = [NSError errorWithDomain:@"foo" code:3 userInfo:errorUserInfo];

    XCTAssertEqual((NSUInteger)451, [FBErrorUtility errorCodeForError:error]);
    XCTAssertEqual((NSUInteger)452, [FBErrorUtility errorSubcodeForError:error]);
}

- (void)testFberrorGetCodeValueForError {
    int code = 1;
    int subCode = 2;
    NSDictionary *errorUserInfo = @{
                                    FBErrorParsedJSONResponseKey : @{
                                            @"body" : @{
                                                    @"error" : @{
                                                            @"code": @(451),
                                                            @"error_subcode" : @(452)
                                                            }
                                                    }
                                            }
                                    };
    NSError *error = [NSError errorWithDomain:@"foo" code:3 userInfo:errorUserInfo];

    // Should correctly extract code & subcode
    [FBErrorUtility fberrorGetCodeValueForError:error index:0 code:&code subcode:&subCode];
    XCTAssertEqual(451, code, @"");
    XCTAssertEqual(452, subCode, @"");

    // Index for single response should have no effect
    code = 1;
    subCode = 2;
    [FBErrorUtility fberrorGetCodeValueForError:error index:4 code:&code subcode:&subCode];
    XCTAssertEqual(451, code, @"");
    XCTAssertEqual(452, subCode, @"");


    // Index should have effect for batch errors
    errorUserInfo = @{
                      FBErrorParsedJSONResponseKey : @[
                              @{
                                  @"body" : @{
                                          @"error" : @{
                                                  @"code": @(551),
                                                  @"error_subcode" : @(552)
                                                  }
                                          }
                                  },
                              @{
                                  @"body" : @{
                                          @"error" : @{
                                                  @"code": @(651),
                                                  @"error_subcode" : @(652)
                                                  }
                                          }
                                },
                              @{
                                  @"body" : @{
                                          @"error" : @{
                                                  @"code": @(751),
                                                  @"error_subcode" : @(752)
                                                  }
                                          }
                                  },
                              ]
                      };
    error = [NSError errorWithDomain:@"foo" code:3 userInfo:errorUserInfo];
    code = 1;
    subCode = 2;
    [FBErrorUtility fberrorGetCodeValueForError:error index:0 code:&code subcode:&subCode];
    XCTAssertEqual(551, code, @"");
    XCTAssertEqual(552, subCode, @"");
    code = 1;
    subCode = 2;
    [FBErrorUtility fberrorGetCodeValueForError:error index:1 code:&code subcode:&subCode];
    XCTAssertEqual(651, code, @"");
    XCTAssertEqual(652, subCode, @"");
    code = 1;
    subCode = 2;
    [FBErrorUtility fberrorGetCodeValueForError:error index:2 code:&code subcode:&subCode];
    XCTAssertEqual(751, code, @"");
    XCTAssertEqual(752, subCode, @"");

    // Should not throw & not cause code/subCode change on incorrect index
    code = 1;
    subCode = 2;
    [FBErrorUtility fberrorGetCodeValueForError:error index:99 code:&code subcode:&subCode];
    XCTAssertEqual(1, code, @"");
    XCTAssertEqual(2, subCode, @"");

    // Should not throw & not cause code/subCode change on all kinds of bad formats
    code = 1;
    subCode = 2;
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:nil] index:99 code:&code subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo"
                                                                    code:1
                                                                userInfo:@{FBErrorParsedJSONResponseKey:@"string"}]
                                          index:99
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo"
                                                                    code:1
                                                                userInfo:@{FBErrorParsedJSONResponseKey:@(1)}]
                                          index:99
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo"
                                                                    code:1
                                                                userInfo:@{FBErrorParsedJSONResponseKey:@[@(1), @(2)]}]
                                          index:99
                                           code:&code
                                        subcode:&subCode];
    NSDictionary *wrongData = @{
      FBErrorParsedJSONResponseKey : @{
              @"body" : @{
                      @"error" : @[]
                      }
              }
      };
    NSDictionary *wrongData2 = @{
                                FBErrorParsedJSONResponseKey : @{
                                        @"body" : @{
                                                @"error" : @{
                                                        @"notCode": @(451),
                                                        @"notsubcode" : @(452)
                                                        }
                                                }
                                        }
                                };
    NSDictionary *wrongData3 = @{
                                 FBErrorParsedJSONResponseKey : @{
                                         @"body" : @"string"
                                         }
                                 };
    NSDictionary *wrongData4 = @{
                                 FBErrorParsedJSONResponseKey : @{
                                         @"body" : [NSNull null]
                                         }
                                 };
    NSDictionary *wrongData5 = @{
                                 FBErrorParsedJSONResponseKey : @[
                                         @{@"body" : [NSNull null]},
                                         @{@"body" : @{}},
                                         @{@"body" : @{@"error":[NSNull null]}},
                                         @{@"body" : @{@"error":@[]}},
                                         ]
                                 };
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData]
                                          index:0
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData]
                                          index:1
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData2]
                                          index:0
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData3]
                                          index:0
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData3]
                                          index:1
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData4]
                                          index:0
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData4]
                                          index:1
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData5]
                                          index:0
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData5]
                                          index:1
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData5]
                                          index:2
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData5]
                                          index:3
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData5]
                                          index:4
                                           code:&code
                                        subcode:&subCode];
    [FBErrorUtility fberrorGetCodeValueForError:[NSError errorWithDomain:@"foo" code:1 userInfo:wrongData5]
                                          index:5
                                           code:&code
                                        subcode:&subCode];
    XCTAssertEqual(1, code, @"");
    XCTAssertEqual(2, subCode, @"");
}

/*
  If there is a checkpoint on the account that prevents the person from logging in, Accounts.framework will return the following NSError:

  Error
  Domain=com.apple.accounts
  Code=7
  "The Facebook server could not fulfill this access request: Error validating access token: You cannot access the app till you log in to www.facebook.com and follow the instructions given. (459)"
  UserInfo={
    NSLocalizedDescription=The Facebook server could not fulfill this access request: Error validating access token: You cannot access the app till you log in to www.facebook.com and follow the instructions given. (459)
  }
*/
- (void)testSystemLoginCheckpointError {
    [self runSystemLoginTestWithServerErrorDescription:@"The Facebook server could not fulfill this access request: Error validating access token: You cannot access the app till you log in to www.facebook.com and follow the instructions given. (459)"
                                      expectedCategory:FBErrorCategoryRetry
                                       expectedSubcode:FBAuthSubcodeUserCheckpointed
                                   expectedUserMessage:@"Your Facebook account is locked. Please log into www.facebook.com to continue."];
}

/*
  If the session in the OAuth token doesn't match what the server expects and the OAuth implementation suspects the password has changed, Accounts.framework will return the following NSError:

  Error
  Domain=com.apple.accounts
  Code=7
  "The Facebook server could not fulfill this access request: Error validating access token: Session does not match current stored session. This may be because the user changed the password since the time the session was created or Facebook has changed the session for security reasons."
  UserInfo={
    NSLocalizedDescription=The Facebook server could not fulfill this access request: Error validating access token: Session does not match current stored session. This may be because the user changed the password since the time the session was created or Facebook has changed the session for security reasons.
  }
*/
- (void)testSystemLoginSessionError {
    [self runSystemLoginTestWithServerErrorDescription:@"The Facebook server could not fulfill this access request: Error validating access token: Session does not match current stored session. This may be because the user changed the password since the time the session was created or Facebook has changed the session for security reasons. (452)"
                                      expectedCategory:FBErrorCategoryAuthenticationReopenSession
                                       expectedSubcode:FBAuthSubcodePasswordChanged
                                   expectedUserMessage:@"Your Facebook password has changed. To confirm your password, open Settings > Facebook and tap your name."];

    [self runSystemLoginTestWithServerErrorDescription:@"The Facebook server could not fulfill this access request: Error validating access token: Session does not match current stored session. This may be because the user changed the password since the time the session was created or Facebook has changed the session for security reasons. (460)"
                                      expectedCategory:FBErrorCategoryAuthenticationReopenSession
                                       expectedSubcode:FBAuthSubcodePasswordChanged
                                   expectedUserMessage:@"Your Facebook password has changed. To confirm your password, open Settings > Facebook and tap your name."];
}

/*
  If a person's account is unconfirmed, Accounts.framework will return the following NSError:

  Error
    Domain=com.apple.accounts
    Code=7
    "The Facebook server could not fulfill this access request: Error validating access token: Sessions for the user  are not allowed because the user is not a confirmed user. (464)"
    UserInfo={
      NSLocalizedDescription=The Facebook server could not fulfill this access request: Error validating access token: Sessions for the user  are not allowed because the user is not a confirmed user. (464)
    }
*/
- (void)testSystemLoginUnconfirmedError {
    [self runSystemLoginTestWithServerErrorDescription:@"The Facebook server could not fulfill this access request: Error validating access token: Sessions for the user  are not allowed because the user is not a confirmed user. (464)"
                                      expectedCategory:FBErrorCategoryAuthenticationReopenSession
                                       expectedSubcode:FBAuthSubcodeUnconfirmedUser
                                   expectedUserMessage:@"Your Facebook account is locked. Please log into www.facebook.com to continue."];
}

- (void)runSystemLoginTestWithServerErrorDescription:(NSString *)errorDescription
                                    expectedCategory:(FBErrorCategory)expectedCategory
                                     expectedSubcode:(int)expectedSubcode
                                 expectedUserMessage:(NSString *)expectedUserMessage {

    NSError *systemError = [NSError errorWithDomain:@"com.apple.accounts" code:7 userInfo:@{
        NSLocalizedDescriptionKey : errorDescription
    }];

    NSError *error = [FBSession errorWithSystemAccountStoreDeniedError:systemError isReauthorize:NO forSession:nil];

    int code = 0;
    int subcode = 0;
    FBErrorCategory category = FBErrorCategoryInvalid;
    NSString *userMessage = nil;
    BOOL shouldNotifyUser = NO;

    [FBErrorUtility fberrorGetCodeValueForError:error
                                          index:0
                                           code:&code
                                        subcode:&subcode];

    category = [FBErrorUtility fberrorCategoryFromError:error
                                                   code:code
                                                subcode:subcode
                                   returningUserMessage:&userMessage
                                    andShouldNotifyUser:&shouldNotifyUser];

    XCTAssertEqual(code, FBOAuthError, @"");
    XCTAssertEqual(subcode, expectedSubcode, @"");
    XCTAssertEqual(category, expectedCategory, @"");
    XCTAssertEqualObjects(userMessage, expectedUserMessage, @"");
    XCTAssertTrue(shouldNotifyUser, @"");
}

@end
