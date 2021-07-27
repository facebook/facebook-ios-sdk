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

import FBSDKCoreKit
import XCTest

class GraphRequestBodyTests: XCTestCase {

  func testBodyCreationWithFormValue() throws {
    let body = GraphRequestBody()
    body.append(withKey: "first_key", formValue: "first_value", logger: nil)
    body.append(withKey: "second_key", formValue: "second_value", logger: nil)

    let decodedData = try XCTUnwrap(String(data: body.data, encoding: .utf8))

    XCTAssertEqual(body.mimeContentType(), "application/json")
    XCTAssertTrue(decodedData.contains(#""first_key":"first_value""#))
    XCTAssertTrue(decodedData.contains(#""second_key":"second_value""#))
  }

  func testBodyCreationWithFormValueWithMultipartType() throws {
    let body = GraphRequestBody()
    body.append(withKey: "first_key", formValue: "first_value", logger: nil)
    body.append(withKey: "second_key", formValue: "second_value", logger: nil)
    body.requiresMultipartDataFormat = true

    let decodedData = try XCTUnwrap(String(data: body.data, encoding: .utf8))

    XCTAssertTrue(body.mimeContentType().contains("multipart/form-data"))
    XCTAssertTrue(decodedData.contains("Content-Disposition: form-data"))
    XCTAssertTrue(decodedData.contains("name=\"first_key\"\r\n\r\nfirst_value\r\n"))
    XCTAssertTrue(decodedData.contains("name=\"second_key\"\r\n\r\nsecond_value\r\n"))
  }

  func testBodyCreationWithImageValue() throws {
    let body = GraphRequestBody()
    body.append(withKey: "image_key", imageValue: UIImage(), logger: nil)

    let decodedData = try XCTUnwrap(String(data: body.data, encoding: .utf8))

    XCTAssertTrue(body.mimeContentType().contains("multipart/form-data"))
    XCTAssertTrue(decodedData.contains("Content-Type: image/jpeg"))
  }

  func testBodyCreationWithDataValue() throws {
    let body = GraphRequestBody()
    body.append(withKey: "data_key", dataValue: Data(), logger: nil)

    let decodedData = try XCTUnwrap(String(data: body.data, encoding: .utf8))

    XCTAssertTrue(body.mimeContentType().contains("multipart/form-data"))
    XCTAssertTrue(decodedData.contains("Content-Type: content/unknown"))
  }

  func testBodyCreationWithAttachmentValue() throws {
    let body = GraphRequestBody()
    let attachment = GraphRequestDataAttachment(
      data: Data(),
      filename: "test_filename",
      contentType: "test_content_type"
    )

    body.append(withKey: "attachment_key", dataAttachmentValue: attachment, logger: nil)

    let decodedData = try XCTUnwrap(String(data: body.data, encoding: .utf8))

    XCTAssertTrue(body.mimeContentType().contains("multipart/form-data"))
    XCTAssertTrue(decodedData.contains("filename=\"test_filename\""))
    XCTAssertTrue(decodedData.contains("Content-Type: test_content_type"))
  }
}
