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

import Foundation

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
    url: SampleUrls.valid,
    mimeType: MimeType.applicationJSON.description,
    expectedContentLength: 0,
    textEncodingName: nil
  )

  static let missingMimeType = HTTPURLResponse(
    url: SampleUrls.valid,
    mimeType: nil,
    expectedContentLength: 0,
    textEncodingName: nil
  )

  static let pngMimeType = HTTPURLResponse(
    url: SampleUrls.valid,
    mimeType: MimeType.png.description,
    expectedContentLength: 0,
    textEncodingName: nil
  )

  static let invalidStatusCode = HTTPURLResponse(
    url: SampleUrls.valid,
    statusCode: 500,
    httpVersion: nil,
    headerFields: nil
  )

  static let validStatusCode = HTTPURLResponse(
    url: SampleUrls.valid,
    statusCode: 200,
    httpVersion: nil,
    headerFields: nil
  )

  static func valid(
    statusCode: Int,
    headerFields: [String: String]? = nil
  ) -> HTTPURLResponse {
    return HTTPURLResponse(
      url: SampleUrls.valid,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: headerFields
    )! // swiftlint:disable:this force_unwrapping
  }
}
