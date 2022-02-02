/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class GraphRequestBodyTests: XCTestCase {

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
    XCTAssertTrue(decodedData.contains(#"filename="test_filename""#))
    XCTAssertTrue(decodedData.contains("Content-Type: test_content_type"))
  }
}
