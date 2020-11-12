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

#import "FBSDKGraphRequestBody.h"
#import "FBSDKGraphRequestDataAttachment.h"

@interface FBSDKGraphRequestBodyTests : XCTestCase
@end

@implementation FBSDKGraphRequestBodyTests

- (void)testBodyCreationWithFormValue
{
  FBSDKGraphRequestBody *body = [FBSDKGraphRequestBody new];
  [body appendWithKey:@"first_key" formValue:@"first_value" logger:nil];
  [body appendWithKey:@"second_key" formValue:@"second_value" logger:nil];

  NSString *decodedData = [[NSString alloc] initWithData:body.data encoding:NSUTF8StringEncoding];

  XCTAssertEqualObjects(body.mimeContentType, @"application/json");
  XCTAssertTrue([decodedData containsString:@"\"first_key\":\"first_value\""]);
  XCTAssertTrue([decodedData containsString:@"\"second_key\":\"second_value\""]);
}

- (void)testBodyCreationWithFormValueWithMultipartType
{
  FBSDKGraphRequestBody *body = [FBSDKGraphRequestBody new];
  [body appendWithKey:@"first_key" formValue:@"first_value" logger:nil];
  [body appendWithKey:@"second_key" formValue:@"second_value" logger:nil];
  body.requiresMultipartDataFormat = YES;

  NSString *decodedData = [[NSString alloc] initWithData:body.data encoding:NSUTF8StringEncoding];

  XCTAssertTrue([body.mimeContentType containsString:@"multipart/form-data"]);
  XCTAssertTrue([decodedData containsString:@"Content-Disposition: form-data"]);
  XCTAssertTrue([decodedData containsString:@"name=\"first_key\"\r\n\r\nfirst_value\r\n"]);
  XCTAssertTrue([decodedData containsString:@"name=\"second_key\"\r\n\r\nsecond_value\r\n"]);
}

- (void)testBodyCreationWithImageValue
{
  FBSDKGraphRequestBody *body = [FBSDKGraphRequestBody new];
  [body appendWithKey:@"image_key" imageValue:[UIImage new] logger:nil];

  NSString *decodedData = [[NSString alloc] initWithData:body.data encoding:NSUTF8StringEncoding];
  XCTAssertTrue([body.mimeContentType containsString:@"multipart/form-data"]);
  XCTAssertTrue([decodedData containsString:@"Content-Type: image/jpeg"]);
}

- (void)testBodyCreationWithDataValue
{
  FBSDKGraphRequestBody *body = [FBSDKGraphRequestBody new];
  [body appendWithKey:@"data_key" dataValue:[NSData data] logger:nil];

  NSString *decodedData = [[NSString alloc] initWithData:body.data encoding:NSUTF8StringEncoding];
  XCTAssertTrue([body.mimeContentType containsString:@"multipart/form-data"]);
  XCTAssertTrue([decodedData containsString:@"Content-Type: content/unknown"]);
}

- (void)testBodyCreationWithAttachmentValue
{
  FBSDKGraphRequestBody *body = [FBSDKGraphRequestBody new];
  FBSDKGraphRequestDataAttachment *attachment = [[FBSDKGraphRequestDataAttachment alloc] initWithData:[NSData data]
                                                                                             filename:@"test_filename"
                                                                                          contentType:@"test_content_type"];
  [body appendWithKey:@"attachment_key" dataAttachmentValue:attachment logger:nil];

  NSString *decodedData = [[NSString alloc] initWithData:body.data encoding:NSUTF8StringEncoding];
  XCTAssertTrue([body.mimeContentType containsString:@"multipart/form-data"]);
  XCTAssertTrue([decodedData containsString:@"filename=\"test_filename\""]);
  XCTAssertTrue([decodedData containsString:@"Content-Type: test_content_type"]);
}

@end
