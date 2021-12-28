/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import TestTools

enum SampleHTTPURLResponses {
  private enum MimeType: Hashable {
    case applicationJSON
    case png

    var description: String {
      switch self {
      case .applicationJSON: return "application/json"
      case .png: return "image/png"
      }
    }
  }

  static let valid = HTTPURLResponse(
    url: SampleURLs.valid,
    mimeType: MimeType.applicationJSON.description,
    expectedContentLength: 0,
    textEncodingName: nil
  )

  static let missingMimeType = HTTPURLResponse(
    url: SampleURLs.valid,
    mimeType: nil,
    expectedContentLength: 0,
    textEncodingName: nil
  )

  static let pngMimeType = HTTPURLResponse(
    url: SampleURLs.valid,
    mimeType: MimeType.png.description,
    expectedContentLength: 0,
    textEncodingName: nil
  )

  static let invalidStatusCode = HTTPURLResponse(
    url: SampleURLs.valid,
    statusCode: 500,
    httpVersion: nil,
    headerFields: nil
  )

  static let validStatusCode = HTTPURLResponse(
    url: SampleURLs.valid,
    statusCode: 200,
    httpVersion: nil,
    headerFields: nil
  )! // swiftlint:disable:this force_unwrapping

  static func valid(
    statusCode: Int,
    headerFields: [String: String]? = nil
  ) -> HTTPURLResponse {
    HTTPURLResponse(
      url: SampleURLs.valid,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: headerFields
    )! // swiftlint:disable:this force_unwrapping
  }
}
