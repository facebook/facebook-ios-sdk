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
import TestTools
import XCTest

class ErrorReportTests: XCTestCase { // swiftlint:disable:this type_body_length

  let code = 2
  let domain = "test"
  let timeInterval = 10.0
  let factory = TestGraphRequestFactory()
  let fileManager = TestFileManager(tempDirectoryURL: SampleUrls.valid)
  let settings = TestSettings()
  let validReportNames = [
    "error_report_1.json",
    "error_report_2.json"
  ]
  var report: ErrorReport! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    TestLogger.reset()
    TestFileDataExtractor.reset()
    SDKError.reset()
    TestFileDataExtractor.reset()

    report = ErrorReport(
      graphRequestProvider: factory,
      fileManager: fileManager,
      settings: settings,
      fileDataExtractor: TestFileDataExtractor.self
    )
  }

  func testCreatingWithDefaults() {
    report = ErrorReport()

    XCTAssertTrue(
      report.requestProvider is GraphRequestFactory,
      "Should use the expected default graph request factory"
    )
    XCTAssertEqual(
      ObjectIdentifier(report.fileManager),
      ObjectIdentifier(FileManager.default),
      "Should use the expected default file manager"
    )
    XCTAssertEqual(
      ObjectIdentifier(report.settings),
      ObjectIdentifier(Settings.shared),
      "Should use the expected default settings"
    )
    XCTAssertTrue(
      report.dataExtractor is NSData.Type,
      "Should use the expected file data extractor type"
    )
  }

  func testCreatingWithDependencies() {
    XCTAssertEqual(
      ObjectIdentifier(report.requestProvider),
      ObjectIdentifier(factory),
      "Should use the provided graph request factory"
    )
    XCTAssertEqual(
      ObjectIdentifier(report.fileManager),
      ObjectIdentifier(fileManager),
      "Should use the provided file manager"
    )
    XCTAssertEqual(
      ObjectIdentifier(report.settings),
      ObjectIdentifier(settings),
      "Should use the provided settings"
    )
    XCTAssertTrue(
      report.dataExtractor is TestFileDataExtractor.Type,
      "Should use the provided file data extractor"
    )
  }

  // MARK: - Enabling

  func testEnablingWithDataProcessingRestricted() {
    settings.stubbedIsDataProcessingRestricted = true
    report.enable()

    XCTAssertTrue(
      report.isEnabled,
      "Enabling error report should set a flag"
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
    report.enable()

    XCTAssertTrue(
      fileManager.contentsOfDirectoryAtPathWasCalled,
      "Should try to retrieve cached error reports when data processing is not restricted"
    )
    XCTAssertEqual(
      fileManager.capturedCreateDirectoryPath,
      report.directoryPath,
      "Should create the missing reports directory"
    )
  }

  func testEnablingWithFailedDirectoryCreation() {
    fileManager.stubbedFileExists = false
    fileManager.stubbedCreateDirectoryShouldSucceed = false
    report.enable()

    XCTAssertTrue(
      report.isEnabled,
      "This is almost surely not the behavior we want"
    )
  }

  // MARK: - Loading Error Reports

  func testLoadingReportsWithoutPersistedReports() {
    let reports = report.loadErrorReports()

    XCTAssertTrue(
      reports.isEmpty,
      "Should not be able to load reports when none are persisted"
    )
  }

  func testLoadingReportsWithInvalidReportNames() {
    fileManager.stubbedContentsOfDirectory = ["foo.jpg", "bar.txt", "baz"]
    let reports = report.loadErrorReports()

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

    let expectedFilePaths = validReportNames.map { report.directoryPath + "/" + $0 }

    report.loadErrorReports()

    XCTAssertEqual(
      TestFileDataExtractor.capturedFileNames.sorted(),
      expectedFilePaths.sorted(),
      "Should attempt to extract data from files with the correct naming convention"
    )
  }

  func testLoadingReportsWithValidReportNamesValidData() {
    seedErrorReportData()

    report.loadErrorReports().forEach { errorReport in
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
    report.uploadErrors()

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

    report.uploadErrors()

    guard let reports = factory.capturedParameters["error_reports"] as? String,
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
    report.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, nil)

    XCTAssertFalse(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading has no result"
    )
  }

  func testCompletingUploadWithoutResultWithError() {
    seedErrorReportData()
    report.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, SampleError())

    XCTAssertFalse(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading fails"
    )
  }

  func testCompletingUploadWithIncorrectResultTypeWithoutError() {
    seedErrorReportData()
    report.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, ["foo"], nil)

    XCTAssertFalse(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading fails"
    )
  }

  func testCompletingUploadWithCorrectResultTypeValidKeyWithoutError() {
    seedErrorReportData()
    report.uploadErrors()
    factory.capturedRequests.first?.capturedCompletionHandler?(nil, ["success": "foo"], nil)

    XCTAssertTrue(
      fileManager.removeItemAtPathWasCalled,
      "Should not clear the saved reports when uploading fails"
    )
  }

  // MARK: - Saving

  func testSavingWhenDisabled() throws {
    report.reset()

    // TODO: Remove when saving uses a stub instead of actual disk
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: report.directoryPath, isDirectory: &isDirectory) {
      try FileManager.default.removeItem(atPath: report.directoryPath)
    }

    report.saveError(1, errorDomain: "foo", message: "bar")

    XCTAssertNil(
      FileManager.default.subpaths(atPath: report.directoryPath),
      "Should not write the error to the reports directory when the reporter is not enabled"
    )
  }

  func testSavingWhenEnabled() throws {
    report.enable()

    // TODO: Remove when saving uses a stub instead of actual disk
    var isDirectory: ObjCBool = false
    if !FileManager.default.fileExists(atPath: report.directoryPath, isDirectory: &isDirectory) {
      try FileManager.default.createDirectory(atPath: report.directoryPath, withIntermediateDirectories: false)
    }

    report.saveError(1, errorDomain: "foo", message: "bar")

    guard let files = FileManager.default.subpaths(atPath: report.directoryPath)
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
