/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class ImageDownloaderTests: XCTestCase {

  let expectedCacheMemory = 1024 * 1024 * 8
  let expectedCacheCapacity = 1024 * 1024 * 100
  let defaultTTL = 60.0
  let provider = TestSessionProvider()
  lazy var downloader = ImageDownloader(sessionProvider: provider)
  lazy var url = SampleURLs.valid(path: name)
  lazy var request = URLRequest(url: url)
  let (image, imageData): (UIImage, Data) = {
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 36, height: 36), false, 1)
    let image = UIGraphicsGetImageFromCurrentImageContext()! // swiftlint:disable:this force_unwrapping
    UIGraphicsEndImageContext()
    let imageData = image.pngData()! // swiftlint:disable:this force_unwrapping
    return (image, imageData)
  }()

  override func setUp() {
    super.setUp()

    downloader.urlCache.removeAllCachedResponses()
  }

  func testDefaultSessionProvider() {
    XCTAssertEqual(
      ObjectIdentifier(ImageDownloader.sharedInstance.sessionProvider),
      ObjectIdentifier(URLSession.shared),
      "Should use the shared system session by default"
    )
  }

  func testCreatingWithSession() {
    XCTAssertEqual(
      ObjectIdentifier(downloader.sessionProvider),
      ObjectIdentifier(provider),
      "Should be able to create with a session provider"
    )
  }

  func testFetchingImageStartsTask() {
    let dataTask = TestSessionDataTask()
    provider.stubbedDataTask = dataTask
    downloader.downloadImage(
      with: url,
      ttl: defaultTTL
    ) { _ in }

    XCTAssertEqual(
      provider.dataTaskCallCount,
      1,
      "Should request a data task when fetching an image"
    )
    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Should start the data task for fetching an image"
    )
  }

  // Data | Response | Error
  // nil  | nil      | nil
  func testCompletingTaskWithMissingDataResponseAndError() {
    completeFetchingImage(
      data: nil,
      response: nil,
      error: nil,
      message: "Should not complete with an image when the session task completes with no inputs"
    )
  }

  // Data | Response | Error
  // nil  | nil      | yes
  func testCompletingTaskWithError() {
    completeFetchingImage(
      data: nil,
      response: nil,
      error: SampleError(),
      message: "Should not complete with an image when the session task completes with an error"
    )
  }

  // Data | Response       | Error
  // nil  | yes (non-http) | nil
  func testCompletingTaskWithNonHTTPResponse() {
    completeFetchingImage(
      data: nil,
      response: SampleHTTPURLResponses.valid,
      error: nil,
      message: "Should not complete with an image when there is non-http response"
    )
  }

  // Data | Response   | Error
  // nil  | yes (http) | nil
  func testCompletingTaskWithInvalidStatusCode() {
    completeFetchingImage(
      data: nil,
      response: SampleHTTPURLResponses.invalidStatusCode,
      error: nil,
      message: "Should not complete with an image when there is an invalid url response status code"
    )
  }

  // Data | Response | Error
  // nil  | yes      | yes
  func testCompletingTaskWithResponseAndError() {
    completeFetchingImage(
      data: nil,
      response: SampleHTTPURLResponses.valid,
      error: SampleError(),
      message: "Should not complete with an image when there is an error"
    )
  }

  // Data           | Response | Error
  // yes (invalid)  | nil      | nil
  func testCompletingTaskWithInvalidData() {
    completeFetchingImage(
      data: SampleGraphResponses.empty.data,
      response: nil,
      error: nil,
      message: "Should not complete with an image when there is invalid data"
    )
  }

  // Data        | Response | Error
  // yes (valid) | nil      | yes
  func testCompletingTaskWithValidDataAndError() {
    completeFetchingImage(
      data: imageData,
      response: nil,
      error: SampleError(),
      message: "Should not complete with an image when there is an error"
    )
  }

  // Data        | Response      | Error
  // yes (valid) | yes (invalid) | nil
  func testCompletingTaskWithValidDataAndInvalidResponse() {
    completeFetchingImage(
      data: imageData,
      response: SampleHTTPURLResponses.invalidStatusCode,
      error: nil,
      message: "Should not complete with an image when there is an invalid response code"
    )
  }

  // Data          | Response    | Error
  // yes (invalid) | yes (valid) | nil
  func testCompletingTaskWithInvalidDataAndValidResponse() {
    completeFetchingImage(
      data: SampleGraphResponses.empty.data,
      response: SampleHTTPURLResponses.validStatusCode,
      error: nil,
      message: "Should not complete with an image when there is invalid image data"
    )
  }

  // Data        | Response    | Error
  // yes (valid) | yes (valid) | nil
  func testCompletingTaskWithValidDataAndValidResponse() {
    completeFetchingImage(
      data: imageData,
      response: SampleHTTPURLResponses.validStatusCode,
      error: nil,
      expectedImage: image,
      message: "Should not complete with an image when there is invalid image data"
    )
  }

  // MARK: - Caching

  func testDefaultCache() {
    XCTAssertEqual(
      downloader.urlCache.memoryCapacity,
      expectedCacheMemory,
      "Should use a well known value for the memory capacity of the image cache"
    )
    XCTAssertEqual(
      downloader.urlCache.diskCapacity,
      expectedCacheCapacity,
      "Should use a well known value for the disk capacity of the image cache"
    )
  }

  func testUncachedImagesAreFetched() {
    downloader.downloadImage(with: url, ttl: defaultTTL, completion: nil)

    XCTAssertEqual(
      provider.dataTaskCallCount,
      1,
      "Should attempt to fetch an uncached image"
    )
  }

  func testUnexpiredCachedImagesAreNotFetched() {
    seedURLCache()
    downloader.downloadImage(with: url, ttl: defaultTTL, completion: nil)

    XCTAssertEqual(
      provider.dataTaskCallCount,
      0,
      "Should not attempt to fetch a cached image"
    )
  }

  func testExpiredCachedImagedAreFetched() {
    seedURLCache(date: .distantPast)
    downloader.downloadImage(with: url, ttl: defaultTTL, completion: nil)

    XCTAssertEqual(
      provider.dataTaskCallCount,
      1,
      "Should attempt to fetch a cached image if it is expired"
    )
  }

  func testFetchingCachedImage() {
    seedURLCache()

    var completionInvoked = false
    downloader.downloadImage(with: url, ttl: defaultTTL) { potentialImage in
      guard let image = potentialImage else {
        return XCTFail("Should call the fetch completion with an image created from cached image data")
      }
      XCTAssertEqual(
        image.pngData(),
        self.imageData,
        "Should call the fetch completion with an image created from cached image data"
      )
      completionInvoked = true
    }

    provider.capturedCompletion?(nil, nil, nil)
    XCTAssertTrue(completionInvoked)
  }

  func testFetchingWithSuccessSavesToCache() {
    let response = SampleHTTPURLResponses.validStatusCode
    downloader.downloadImage(with: url, ttl: defaultTTL) { _ in }

    provider.capturedCompletion?(imageData, response, nil)

    let expectedCachedResponse = CachedURLResponse(response: response, data: imageData)
    guard let cachedResponse = downloader.urlCache.cachedResponse(for: request) else {
      return XCTFail("Should have a cached response")
    }

    XCTAssertEqual(
      cachedResponse.data,
      expectedCachedResponse.data,
      "Should cache a successful fetch"
    )
  }

  func testClearingCache() {
    seedURLCache()
    downloader.removeAll()

    XCTAssertNil(downloader.urlCache.cachedResponse(for: request))
  }

  // MARK: - Helpers

  func seedURLCache(date: Date = Date()) {
    downloader.urlCache.storeCachedResponse(
      CachedURLResponse(
        response: SampleHTTPURLResponses.validStatusCode,
        data: imageData,
        userInfo: ["timestamp": date],
        storagePolicy: URLCache.StoragePolicy.allowed
      ),
      for: request
    )
    XCTAssertNotNil(downloader.urlCache.cachedResponse(for: request))
  }

  func completeFetchingImage(
    data: Data?,
    response: URLResponse?,
    error: Error?,
    expectedImage: UIImage? = nil,
    message: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    var completionInvoked = false
    var image: UIImage?
    downloader.downloadImage(
      with: SampleURLs.valid,
      ttl: 0
    ) { potentialImage in
      image = potentialImage
      completionInvoked = true
    }

    provider.capturedCompletion?(data, response, error)

    XCTAssertEqual(
      image?.pngData(),
      expectedImage?.pngData(),
      message,
      file: file,
      line: line
    )
    XCTAssertTrue(
      completionInvoked,
      file: file,
      line: line
    )
  }
}
