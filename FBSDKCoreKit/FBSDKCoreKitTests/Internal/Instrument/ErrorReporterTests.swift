/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class ErrorReporterTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var factory: TestGraphRequestFactory!
  var fileManager: TestFileManager!
  var settings: TestSettings!
  var reporter: ErrorReporter!
  // swiftlint:enable implicitly_unwrapped_optional

  let code = 2
  let domain = "test"
  let timeInterval = 10.0
  let validReportNames = [
    "error_report_1.json",
    "error_report_2.json",
  ]

  override func setUp() {
    super.setUp()

    TestLogger.reset()
    TestFileDataExtractor.reset()
    TestFileDataExtractor.reset()

    factory = TestGraphRequestFactory()
    fileManager = TestFileManager(tempDirectoryURL: SampleURLs.valid)
    settings = TestSettings()
    reporter = ErrorReporter(
      graphRequestFactory: factory,
      fileManager: fileManager,
      settings: settings,
      fileDataExtractor: TestFileDataExtractor.self
    )
  }

  override func tearDown() {
    factory = nil
    fileManager = nil
    settings = nil
    reporter = nil

    super.tearDown()
  }

  func testCreatingWithDefaults() {
    reporter = ErrorReporter.shared

    XCTAssertTrue(
      reporter.graphRequestFactory is GraphRequestFactory,
      "Should use the expected default graph request factory"
    )
    XCTAssertTrue(
      reporter.fileManager === FileManager.default,
      "Should use the expected default file manager"
    )
    XCTAssertTrue(
      reporter.settings is Settings,
      "Should use the expected default settings"
    )
    XCTAssertTrue(
      reporter.dataExtractor is NSData.Type,
      "Should use the expected file data extractor type"
    )
  }

  func testCreatingWithDependencies() {
    XCTAssertEqual(
      ObjectIdentifier(reporter.graphRequestFactory),
      ObjectIdentifier(factory),
      "Should use the provided graph request factory"
    )
    XCTAssertEqual(
      ObjectIdentifier(reporter.fileManager),
      ObjectIdentifier(fileManager),
      "Should use the provided file manager"
    )
    XCTAssertEqual(
      ObjectIdentifier(reporter.settings),
      ObjectIdentifier(settings),
      "Should use the provided settings"
    )
    XCTAssertTrue(
      reporter.dataExtractor is TestFileDataExtractor.Type,
      "Should use the provided file data extractor"
    )
  }

  // MARK: - Enabling

  func testEnablingWithDataProcessingRestricted() {
    settings.isDataProcessingRestricted = true
    reporter.enable()

    XCTAssertTrue(
      reporter.isEnabled,
      "Enabling error reporter should set a flag"
    )
    XCTAssertFalse(
      fileManager.contentsOfDirectoryAtPathWasCalled,
      "Should not try to retrieve cached error reports when data processing is restricted"
    )
    XCTAssertNil(
      factory.capturedGraphPath,
      "Should not try to post error reports when data processing is restricted"
    )
  }

  func testEnablingWithoutDirectory() {
    fileManager.stubbedFileExists = false
    reporter.enable()

    XCTAssertTrue(
      fileManager.contentsOfDirectoryAtPathWasCalled,
      "Should try to retrieve cached error reports when data processing is not restricted"
    )
    XCTAssertEqual(
      fileManager.capturedCreateDirectoryPath,
      reporter.directoryPath,
      "Should create the missing reports directory"
    )
  }

  func testEnablingWithFailedDirectoryCreation() {
    fileManager.stubbedFileExists = false
    fileManager.stubbedCreateDirectoryShouldSucceed = false
    reporter.enable()

    XCTAssertTrue(
      reporter.isEnabled,
      "This is almost surely not the behavior we want"
    )
  }

  // MARK: - Loading Error Reports

  func testLoadingReportsWithoutPersistedReports() {
    let reports = reporter.loadErrorReports()

    XCTAssertTrue(
      reports.isEmpty,
      "Should not be able to load reports when none are persisted"
    )
  }

  func testLoadingReportsWithInvalidReportNames() {
    fileManager.stubbedContentsOfDirectory = ["foo.jpg", "bar.txt", "baz"]
    let reports = reporter.loadErrorReports()

    XCTAssertTrue(
      reports.isEmpty,
      "Should not be able to load reports when no valid reports are persisted"
    )
    XCTAssertTrue(
      TestFileDataExtractor.capturedFileNames.isEmpty,
      "Should ignore files with the incorrect naming conventions"
    )
  }

  func testLoadingReportsWithValidReportNames() {
    fileManager.stubbedContentsOfDirectory = validReportNames

    let expectedFilePaths = validReportNames.map { reporter.directoryPath + "/" + $0 }

    reporter.loadErrorReports()

    XCTAssertEqual(
      TestFileDataExtractor.capturedFileNames.sorted(),
      expectedFilePaths.sorted(),
      "Should attempt to extract data from files with the correct naming convention"
    )
  }

  func testLoadingReportsWithValidReportNamesValidData() {
    seedErrorReportData()

    reporter.loadErrorReports().forEach { errorReport in
      do {
        let data = try JSONSerialization.data(withJSONObject: errorReport, options: [])
        let decoded = try JSONDecoder().decode(CodableError.self, from: data)

        XCTAssertEqual(
          decoded,
          validError,
          "Should load the error in a format that can be serialized and encoded"
        )
      } catch {
        XCTFail(String(describing: error))
      }
    }
  }

  // MARK: - Uploading

  func testUploadingWithoutSavedErrorReports() {
    reporter.uploadErrors()

    XCTAssertTrue(
      fileManager.contentsOfDirectoryAtPathWasCalled,
      "Should try to retrieve cached error reports when uploading"
    )
    XCTAssertNil(
      factory.capturedGraphPath,
      "Should not try to upload empty list of error reports"
    )
  }

  func testUploadingWithSavedErrorReports() throws {
    seedErrorReportData()
    settings.appID = name

    reporter.uploadErrors()

    guard
      let reports = factory.capturedParameters["error_reports"] as? String,
      let data = reports.data(using: .utf8)
    else {
      return XCTFail("Should upload reports as an array of strings")
    }
    let decoded = try JSONDecoder().decode([CodableError].self, from: data)

    XCTAssertEqual(
      factory.capturedGraphPath,
      "\(name)/instruments",
      "Should upload retrieved error reports to the correct graph path"
    )
    XCTAssertEqual(
      decoded,
      [validError, validError],
      "Should upload the expected reports"
    )
    XCTAssertEqual(
      factory.capturedHttpMethod,
      .post,
      "Should use the correct http method"
    )
  }

  func testCompletingUploadWithoutResultWithoutError() {
    seedErrorReportData()
    reporter.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, nil)

    XCTAssertFalse(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading has no result"
    )
  }

  func testCompletingUploadWithoutResultWithError() {
    seedErrorReportData()
    reporter.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, SampleError())

    XCTAssertFalse(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading fails"
    )
  }

  func testCompletingUploadWithIncorrectResultTypeWithoutError() {
    seedErrorReportData()
    reporter.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, ["foo"], nil)

    XCTAssertFalse(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading fails"
    )
  }

  func testCompletingUploadWithCorrectResultTypeValidKeyWithoutError() {
    seedErrorReportData()
    reporter.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, ["success": "foo"], nil)

    XCTAssertTrue(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading fails"
    )
  }

  // MARK: - Saving

  func testSavingWhenDisabled() throws {
    reporter.reset()

    // TODO: Remove when saving uses a stub instead of actual disk
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: reporter.directoryPath, isDirectory: &isDirectory) {
      try FileManager.default.removeItem(atPath: reporter.directoryPath)
    }

    reporter.saveError(1, errorDomain: "foo", message: "bar")

    XCTAssertNil(
      FileManager.default.subpaths(atPath: reporter.directoryPath),
      "Should not write the error to the reports directory when the reporter is not enabled"
    )
  }

  func testSavingWhenEnabled() throws {
    reporter.enable()

    // TODO: Remove when saving uses a stub instead of actual disk
    var isDirectory: ObjCBool = false
    if !FileManager.default.fileExists(atPath: reporter.directoryPath, isDirectory: &isDirectory) {
      try FileManager.default.createDirectory(atPath: reporter.directoryPath, withIntermediateDirectories: false)
    }

    reporter.saveError(1, errorDomain: "foo", message: "bar")

    guard let files = FileManager.default.subpaths(atPath: reporter.directoryPath)
    else {
      return XCTFail("Should write the error to the reports directory when the reporter is enabled")
    }
    XCTAssertTrue(
      files.contains { $0.hasPrefix("error_report") && $0.hasSuffix(".json") },
      "Should contain the file with the error report"
    )
  }

  // MARK: - Helpers

  var validError: CodableError {
    CodableError(
      code: code,
      domain: domain,
      timestamp: Date(timeIntervalSince1970: timeInterval)
    )
  }

  var encodedError: Data {
    try! JSONEncoder().encode(validError) // swiftlint:disable:this force_try
  }

  func seedErrorReportData() {
    fileManager.stubbedContentsOfDirectory = validReportNames
    TestFileDataExtractor.stubbedData = encodedError
  }

  struct CodableError: Codable, Equatable {
    let code: Int
    let domain: String
    let timestamp: Date

    init(code: Int, domain: String, timestamp: Date) {
      self.code = code
      self.domain = domain
      self.timestamp = timestamp
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(code, forKey: .code)
      try container.encode(domain, forKey: .domain)
      try container.encode(timestamp.timeIntervalSinceReferenceDate, forKey: .timestamp)
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      code = try container.decode(Int.self, forKey: .code)
      domain = try container.decode(String.self, forKey: .domain)
      timestamp = Date(timeIntervalSinceReferenceDate: try container.decode(Double.self, forKey: .timestamp))
    }

    enum CodingKeys: String, CodingKey {
      case code = "error_code"
      case domain
      case timestamp
    }
  }
}
