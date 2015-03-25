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

#import <Foundation/Foundation.h>

#import <OCMock/OCMock.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <XCTest/XCTest.h>

#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKCoreKit+Internal.h"

@interface FBSDKBridgeAPIProtocolNativeV1Tests : XCTestCase
@property (nonatomic, copy) NSString *actionID;
@property (nonatomic, copy) NSString *methodName;
@property (nonatomic, copy) NSString *methodVersion;
@property (nonatomic, strong) FBSDKBridgeAPIProtocolNativeV1 *protocol;

@property (nonatomic, copy) NSString *scheme;
@end

@implementation FBSDKBridgeAPIProtocolNativeV1Tests

- (void)setUp
{
  [super setUp];

  self.actionID = [[NSUUID UUID] UUIDString];
  self.scheme = [[NSUUID UUID] UUIDString];
  self.methodName = [[NSUUID UUID] UUIDString];
  self.methodVersion = [[NSUUID UUID] UUIDString];
  self.protocol = [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:self.scheme];
}

- (void)testRequestURL
{
  NSDictionary *parameters = @{
                               @"api_key_1": @"value1",
                               @"api_key_2": @"value2",
                               };
  NSError *error;
  NSURL *requestURL = [self.protocol requestURLWithActionID:self.actionID
                                                     scheme:self.scheme
                                                 methodName:self.methodName
                                              methodVersion:self.methodVersion
                                                 parameters:parameters
                                                      error:&error];
  XCTAssertNil(error);
  NSString *expectedPrefix = [[NSString alloc] initWithFormat:@"%@://dialog/%@?", self.scheme, self.methodName];
  XCTAssertTrue([[requestURL absoluteString] hasPrefix:expectedPrefix]);
  // Due to the non-deterministic order of Dictionary->JSON serialization, we cannot do string comparisons to verify.
  NSDictionary *queryParameters = [FBSDKUtility dictionaryWithQueryString:requestURL.query];
  NSSet *expectedKeys = [NSSet setWithObjects:@"bridge_args", @"method_args", @"version", nil];
  XCTAssertEqualObjects([NSSet setWithArray:[queryParameters allKeys]], expectedKeys);
  XCTAssertEqualObjects([FBSDKInternalUtility objectForJSONString:queryParameters[@"method_args"] error:NULL], parameters);
}

- (void)testNilResponseParameters
{
  BOOL cancelled = YES;
  NSError *error;

  XCTAssertNil([self.protocol responseParametersForActionID:self.actionID
                                            queryParameters:nil
                                                  cancelled:&cancelled
                                                      error:&error]);
  XCTAssertFalse(cancelled);
  XCTAssertNil(error);

  XCTAssertNil([self.protocol responseParametersForActionID:self.actionID
                                            queryParameters:@{}
                                                  cancelled:&cancelled
                                                      error:&error]);
  XCTAssertFalse(cancelled);
  XCTAssertNil(error);
}

- (void)testEmptyResponseParameters
{
  BOOL cancelled = YES;
  NSError *error;

  NSDictionary *queryParameters = @{
                                    @"bridge_args": @{
                                        @"action_id": self.actionID,
                                        },
                                    @"method_results": @{},
                                    };
  queryParameters = [self _encodeQueryParameters:queryParameters];
  XCTAssertEqualObjects([self.protocol responseParametersForActionID:self.actionID
                                                     queryParameters:queryParameters
                                                           cancelled:&cancelled
                                                               error:&error], @{});
  XCTAssertFalse(cancelled);
  XCTAssertNil(error);
}

- (void)testResponseParameters
{
  BOOL cancelled = YES;
  NSError *error;

  NSDictionary *responseParameters = @{
                                       @"result_key_1": @1,
                                       @"result_key_2": @"two",
                                       @"result_key_3": @{
                                           @"result_key_4": @4,
                                           @"result_key_5": @"five",
                                           },
                                       };
  NSDictionary *queryParameters = @{
                                    @"bridge_args": @{
                                        @"action_id": self.actionID,
                                        },
                                    @"method_results": responseParameters,
                                    };
  queryParameters = [self _encodeQueryParameters:queryParameters];
  XCTAssertEqualObjects([self.protocol responseParametersForActionID:self.actionID
                                                     queryParameters:queryParameters
                                                           cancelled:&cancelled
                                                               error:&error], responseParameters);
  XCTAssertFalse(cancelled);
  XCTAssertNil(error);
}

- (void)testInvalidActionID
{
  BOOL cancelled = YES;
  NSError *error;

  NSDictionary *responseParameters = @{
                                       @"result_key_1": @1,
                                       @"result_key_2": @"two",
                                       @"result_key_3": @{
                                           @"result_key_4": @4,
                                           @"result_key_5": @"five",
                                           },
                                       };
  NSDictionary *queryParameters = @{
                                    @"bridge_args": @{
                                        @"action_id": [[NSUUID UUID] UUIDString],
                                        },
                                    @"method_results": responseParameters,
                                    };
  queryParameters = [self _encodeQueryParameters:queryParameters];
  XCTAssertNil([self.protocol responseParametersForActionID:self.actionID
                                            queryParameters:queryParameters
                                                  cancelled:&cancelled
                                                      error:&error]);
  XCTAssertFalse(cancelled);
  XCTAssertNil(error);
}

- (void)testInvalidBridgeArgs
{
  BOOL cancelled = YES;
  NSError *error;

  NSString *bridgeArgs = @"this is an invalid bridge_args value";
  NSDictionary *queryParameters = @{
                                    @"bridge_args": bridgeArgs,
                                    @"method_results": @{
                                        @"result_key_1": @1,
                                        @"result_key_2": @"two",
                                        },
                                    };
  queryParameters = [self _encodeQueryParameters:queryParameters];
  XCTAssertNil([self.protocol responseParametersForActionID:self.actionID
                                            queryParameters:queryParameters
                                                  cancelled:&cancelled
                                                      error:&error]);
  XCTAssertFalse(cancelled);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqual(error.domain, FBSDKErrorDomain);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"bridge_args");
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentValueKey], bridgeArgs);
  XCTAssertNotNil(error.userInfo[FBSDKErrorDeveloperMessageKey]);
  XCTAssertNotNil(error.userInfo[NSUnderlyingErrorKey]);
}

- (void)testInvalidMethodResults
{
  BOOL cancelled = YES;
  NSError *error;

  NSString *methodResults = @"this is an invalid method_results value";
  NSDictionary *queryParameters = @{
                                    @"bridge_args": @{
                                        @"action_id": self.actionID,
                                        },
                                    @"method_results": methodResults,
                                    };
  queryParameters = [self _encodeQueryParameters:queryParameters];
  XCTAssertNil([self.protocol responseParametersForActionID:self.actionID
                                            queryParameters:queryParameters
                                                  cancelled:&cancelled
                                                      error:&error]);
  XCTAssertFalse(cancelled);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqual(error.domain, FBSDKErrorDomain);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"method_results");
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentValueKey], methodResults);
  XCTAssertNotNil(error.userInfo[FBSDKErrorDeveloperMessageKey]);
  XCTAssertNotNil(error.userInfo[NSUnderlyingErrorKey]);
}

- (void)testResultError
{
  BOOL cancelled = YES;
  NSError *error;

  NSInteger code = 42;
  NSString *domain = @"my custom error domain";
  NSDictionary *userInfo = @{
                             @"key_1": @1,
                             @"key_2": @"two",
                             };
  NSDictionary *queryParameters = @{
                                    @"bridge_args": @{
                                        @"action_id": self.actionID,
                                        @"error": @{
                                            @"code": @(code),
                                            @"domain": domain,
                                            @"user_info": userInfo,
                                            },
                                        },
                                    @"method_results": @{
                                        @"result_key_1": @1,
                                        @"result_key_2": @"two",
                                        },
                                    };
  queryParameters = [self _encodeQueryParameters:queryParameters];
  XCTAssertNil([self.protocol responseParametersForActionID:self.actionID
                                            queryParameters:queryParameters
                                                  cancelled:&cancelled
                                                      error:&error]);
  XCTAssertFalse(cancelled);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, code);
  XCTAssertEqualObjects(error.domain, domain);
  XCTAssertEqualObjects(error.userInfo, userInfo);
}

- (void)testResultCancel
{
  BOOL cancelled = NO;
  NSError *error;

  NSDictionary *queryParameters = @{
                                    @"bridge_args": @{
                                        @"action_id": self.actionID,
                                        },
                                    @"method_results": @{
                                        @"completionGesture": @"cancel",
                                        },
                                    };
  queryParameters = [self _encodeQueryParameters:queryParameters];
  XCTAssertNotNil([self.protocol responseParametersForActionID:self.actionID
                                               queryParameters:queryParameters
                                                     cancelled:&cancelled
                                                         error:&error]);
  XCTAssertTrue(cancelled);
  XCTAssertNil(error);
}

- (void)testRequestParametersWithDataJSON
{
  FBSDKBridgeAPIProtocolNativeV1 *protocol = [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:self.scheme
                                                                                            pasteboard:nil
                                                                                   dataLengthThreshold:NSUIntegerMax
                                                                                        includeAppIcon:NO];
  NSDictionary *parameters = @{
                               @"api_key_1": @"value1",
                               @"api_key_2": @"value2",
                               @"data": [self _testData],
                               };
  NSError *error;
  NSURL *requestURL = [protocol requestURLWithActionID:self.actionID
                                                scheme:self.scheme
                                            methodName:self.methodName
                                         methodVersion:self.methodVersion
                                            parameters:parameters
                                                 error:&error];
  XCTAssertNil(error);
  NSString *expectedPrefix = [[NSString alloc] initWithFormat:@"%@://dialog/%@?", self.scheme, self.methodName];
  XCTAssertTrue([[requestURL absoluteString] hasPrefix:expectedPrefix]);
  // Due to the non-deterministic order of Dictionary->JSON serialization, we cannot do string comparisons to verify.
  NSDictionary *queryParameters = [FBSDKUtility dictionaryWithQueryString:requestURL.query];
  NSSet *expectedKeys = [NSSet setWithObjects:@"bridge_args", @"method_args", @"version", nil];
  XCTAssertEqualObjects([NSSet setWithArray:[queryParameters allKeys]], expectedKeys);
  NSMutableDictionary *expectedMethodArgs = [parameters mutableCopy];
  expectedMethodArgs[@"data"] = [self _testDataSerialized:(NSData *)parameters[@"data"]];
  NSDictionary *methodArgs = [FBSDKInternalUtility objectForJSONString:queryParameters[@"method_args"] error:NULL];
  XCTAssertEqualObjects(methodArgs, expectedMethodArgs);
  NSData *decodedData = [FBSDKBase64 decodeAsData:methodArgs[@"data"][@"fbAppBridgeType_jsonReadyValue"]];
  XCTAssertEqualObjects(decodedData, parameters[@"data"]);
}

- (void)testRequestParametersWithImageJSON
{
  FBSDKBridgeAPIProtocolNativeV1 *protocol = [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:self.scheme
                                                                                            pasteboard:nil
                                                                                   dataLengthThreshold:NSUIntegerMax
                                                                                        includeAppIcon:NO];
  NSDictionary *parameters = @{
                               @"api_key_1": @"value1",
                               @"api_key_2": @"value2",
                               @"image": [self _testImage],
                               };
  NSError *error;
  NSURL *requestURL = [protocol requestURLWithActionID:self.actionID
                                                scheme:self.scheme
                                            methodName:self.methodName
                                         methodVersion:self.methodVersion
                                            parameters:parameters
                                                 error:&error];
  XCTAssertNil(error);
  NSString *expectedPrefix = [[NSString alloc] initWithFormat:@"%@://dialog/%@?", self.scheme, self.methodName];
  XCTAssertTrue([[requestURL absoluteString] hasPrefix:expectedPrefix]);
  // Due to the non-deterministic order of Dictionary->JSON serialization, we cannot do string comparisons to verify.
  NSDictionary *queryParameters = [FBSDKUtility dictionaryWithQueryString:requestURL.query];
  NSSet *expectedKeys = [NSSet setWithObjects:@"bridge_args", @"method_args", @"version", nil];
  XCTAssertEqualObjects([NSSet setWithArray:[queryParameters allKeys]], expectedKeys);
  NSMutableDictionary *expectedMethodArgs = [parameters mutableCopy];
  expectedMethodArgs[@"image"] = [self _testImageSerialized:(UIImage *)parameters[@"image"]];
  NSDictionary *methodArgs = [FBSDKInternalUtility objectForJSONString:queryParameters[@"method_args"] error:NULL];
  XCTAssertEqualObjects(methodArgs, expectedMethodArgs);
  NSData *decodedData = [FBSDKBase64 decodeAsData:methodArgs[@"image"][@"fbAppBridgeType_jsonReadyValue"]];
  XCTAssertNotNil([UIImage imageWithData:decodedData]);
}

- (void)testRequestParametersWithDataPasteboard
{
  id pasteboard = [OCMockObject mockForClass:[UIPasteboard class]];
  NSString *pasteboardName = [[NSUUID UUID] UUIDString];
  NSData *data = [self _testData];
  [[[pasteboard stub] andReturn:pasteboardName] name];
  [[pasteboard expect] setData:data forPasteboardType:@"com.facebook.Facebook.FBAppBridgeType"];
  FBSDKBridgeAPIProtocolNativeV1 *protocol = [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:self.scheme
                                                                                            pasteboard:pasteboard
                                                                                   dataLengthThreshold:0
                                                                                        includeAppIcon:NO];
  NSDictionary *parameters = @{
                               @"api_key_1": @"value1",
                               @"api_key_2": @"value2",
                               @"data": data,
                               };
  NSError *error;
  NSURL *requestURL = [protocol requestURLWithActionID:self.actionID
                                                scheme:self.scheme
                                            methodName:self.methodName
                                         methodVersion:self.methodVersion
                                            parameters:parameters
                                                 error:&error];
  XCTAssertNil(error);
  [pasteboard verify];
  NSString *expectedPrefix = [[NSString alloc] initWithFormat:@"%@://dialog/%@?", self.scheme, self.methodName];
  XCTAssertTrue([[requestURL absoluteString] hasPrefix:expectedPrefix]);
  // Due to the non-deterministic order of Dictionary->JSON serialization, we cannot do string comparisons to verify.
  NSDictionary *queryParameters = [FBSDKUtility dictionaryWithQueryString:requestURL.query];
  NSSet *expectedKeys = [NSSet setWithObjects:@"bridge_args", @"method_args", @"version", nil];
  XCTAssertEqualObjects([NSSet setWithArray:[queryParameters allKeys]], expectedKeys);
  NSMutableDictionary *expectedMethodArgs = [parameters mutableCopy];
  expectedMethodArgs[@"data"] = [self _testDataContainerWithPasteboardName:pasteboardName tag:@"data"];
  NSDictionary *methodArgs = [FBSDKInternalUtility objectForJSONString:queryParameters[@"method_args"] error:NULL];
  XCTAssertEqualObjects(methodArgs, expectedMethodArgs);
}

- (void)testRequestParametersWithImagePasteboard
{
  id pasteboard = [OCMockObject mockForClass:[UIPasteboard class]];
  NSString *pasteboardName = [[NSUUID UUID] UUIDString];
  UIImage *image = [self _testImage];
  NSData *data = [self _testDataWithImage:image];
  [[[pasteboard stub] andReturn:pasteboardName] name];
  [[pasteboard expect] setData:data forPasteboardType:@"com.facebook.Facebook.FBAppBridgeType"];
  FBSDKBridgeAPIProtocolNativeV1 *protocol = [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:self.scheme
                                                                                            pasteboard:pasteboard
                                                                                   dataLengthThreshold:0
                                                                                        includeAppIcon:NO];
  NSDictionary *parameters = @{
                               @"api_key_1": @"value1",
                               @"api_key_2": @"value2",
                               @"image": image,
                               };
  NSError *error;
  NSURL *requestURL = [protocol requestURLWithActionID:self.actionID
                                                scheme:self.scheme
                                            methodName:self.methodName
                                         methodVersion:self.methodVersion
                                            parameters:parameters
                                                 error:&error];
  XCTAssertNil(error);
  [pasteboard verify];
  NSString *expectedPrefix = [[NSString alloc] initWithFormat:@"%@://dialog/%@?", self.scheme, self.methodName];
  XCTAssertTrue([[requestURL absoluteString] hasPrefix:expectedPrefix]);
  // Due to the non-deterministic order of Dictionary->JSON serialization, we cannot do string comparisons to verify.
  NSDictionary *queryParameters = [FBSDKUtility dictionaryWithQueryString:requestURL.query];
  NSSet *expectedKeys = [NSSet setWithObjects:@"bridge_args", @"method_args", @"version", nil];
  XCTAssertEqualObjects([NSSet setWithArray:[queryParameters allKeys]], expectedKeys);
  NSMutableDictionary *expectedMethodArgs = [parameters mutableCopy];
  expectedMethodArgs[@"image"] = [self _testDataContainerWithPasteboardName:pasteboardName tag:@"png"];
  NSDictionary *methodArgs = [FBSDKInternalUtility objectForJSONString:queryParameters[@"method_args"] error:NULL];
  XCTAssertEqualObjects(methodArgs, expectedMethodArgs);
}

- (NSDictionary *)_encodeQueryParameters:(NSDictionary *)queryParameters
{
  NSMutableDictionary *encoded = [[NSMutableDictionary alloc] init];
  [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if (![FBSDKInternalUtility dictionary:encoded setJSONStringForObject:obj forKey:key error:NULL]) {
      [FBSDKInternalUtility dictionary:encoded setObject:obj forKey:key];
    }
  }];
  return [encoded copy];
}

- (NSData *)_testData
{
  NSMutableData *data = [[NSMutableData alloc] initWithLength:1024];
  arc4random_buf((void *)data.bytes, data.length);
  return data;
}

- (NSDictionary *)_testDataContainerWithPasteboardName:(NSString *)pasteboardName tag:(NSString *)tag
{
  return @{
           @"isPasteboard": @YES,
           @"tag": tag,
           @"fbAppBridgeType_jsonReadyValue": pasteboardName,
           };
}

- (NSDictionary *)_testDataSerialized:(NSData *)data
{
  return [self _testDataSerialized:data tag:@"data"];
}

- (NSDictionary *)_testDataSerialized:(NSData *)data tag:(NSString *)tag
{
  NSString *string = [FBSDKBase64 encodeData:data];
  return @{
           @"isBase64": @YES,
           @"tag": tag,
           @"fbAppBridgeType_jsonReadyValue": string,
           };
}

- (NSData *)_testDataWithImage:(UIImage *)image
{
  return UIImageJPEGRepresentation(image, [FBSDKSettings JPEGCompressionQuality]);
}

- (UIImage *)_testImage
{
  UIGraphicsBeginImageContext(CGSizeMake(10.0, 10.0));
  CGContextRef context = UIGraphicsGetCurrentContext();
  [[UIColor redColor] setFill];
  CGContextFillRect(context, CGRectMake(0.0, 0.0, 5.0, 5.0));
  [[UIColor greenColor] setFill];
  CGContextFillRect(context, CGRectMake(5.0, 0.0, 5.0, 5.0));
  [[UIColor blueColor] setFill];
  CGContextFillRect(context, CGRectMake(5.0, 5.0, 5.0, 5.0));
  [[UIColor yellowColor] setFill];
  CGContextFillRect(context, CGRectMake(0.0, 5.0, 5.0, 5.0));
  CGImageRef imageRef = CGBitmapContextCreateImage(context);
  UIGraphicsEndImageContext();
  UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
  CGImageRelease(imageRef);
  return image;
}

- (NSDictionary *)_testImageSerialized:(UIImage *)image
{
  NSData *data = [self _testDataWithImage:image];
  return [self _testDataSerialized:data tag:@"png"];
}

@end
