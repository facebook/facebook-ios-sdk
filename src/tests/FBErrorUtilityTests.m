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
#import "FBTests.h"

@interface FBErrorUtilityTests : FBTests
@end

@implementation FBErrorUtilityTests

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

@end
