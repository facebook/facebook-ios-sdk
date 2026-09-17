/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// URLProtocol stub that returns canned responses or errors for in-process URL requests.
/// Captures the most recent request so tests can assert on headers and body.
final class StubURLProtocol: URLProtocol {

  static var stubbedData: Data?
  static var stubbedStatusCode = 200
  static var stubbedError: Error?
  static var lastRequest: URLRequest?
  static var lastBody: Data?

  static func reset() {
    stubbedData = nil
    stubbedStatusCode = 200
    stubbedError = nil
    lastRequest = nil
    lastBody = nil
  }

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.lastRequest = request
    // URLProtocol doesn't expose httpBodyStream as Data; URLSession converts httpBody to a stream
    // before reaching us, so read it here so tests can assert on the JSON payload.
    if let stream = request.httpBodyStream {
      Self.lastBody = Self.readAll(from: stream)
    } else {
      Self.lastBody = request.httpBody
    }

    if let error = Self.stubbedError {
      client?.urlProtocol(self, didFailWithError: error)
      return
    }

    // swiftlint:disable force_unwrapping
    let response = HTTPURLResponse(
      url: request.url ?? URL(string: "https://example.com")!,
      statusCode: Self.stubbedStatusCode,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )!
    // swiftlint:enable force_unwrapping
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    if let data = Self.stubbedData {
      client?.urlProtocol(self, didLoad: data)
    }
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}

  private static func readAll(from stream: InputStream) -> Data {
    var data = Data()
    stream.open()
    let bufferSize = 4096
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer {
      buffer.deallocate()
      stream.close()
    }
    while stream.hasBytesAvailable {
      let read = stream.read(buffer, maxLength: bufferSize)
      if read <= 0 { break }

      data.append(buffer, count: read)
    }
    return data
  }
}
