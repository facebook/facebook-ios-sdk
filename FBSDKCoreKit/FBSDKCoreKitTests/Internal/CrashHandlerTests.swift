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

class CrashHandlersTest: XCTestCase {

  var crashHandler: CrashHandler! // swiftlint:disable:this implicitly_unwrapped_optional
  var testFileManager: FileManaging! // swiftlint:disable:this implicitly_unwrapped_optional
  var testBundle: TestBundle! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    testFileManager = TestFileManager(tempDirectoryURL: URL(fileURLWithPath: "1"))
    testBundle = TestBundle()
    crashHandler = CrashHandler(
      fileManager: testFileManager,
      bundle: testBundle,
      dataExtractor: TestFileDataExtractor.self
    )
  }

  func testCreatingWithCustomFileManager() {
    XCTAssertTrue(
      crashHandler.fileManager is TestFileManager,
      "Should be able to create with custom file managing"
    )
  }

  func testCreatingWithCustomBundle() {
    XCTAssertTrue(
      crashHandler.bundle is TestBundle,
      "Should be able to create with custom bundle"
    )
  }

  func testCreatingWithCustomDataExtractor() {
    XCTAssertTrue(
      crashHandler.dataExtractor is TestFileDataExtractor.Type,
      "Should be able to create with custom data extractor"
    )
  }

  func testGetFBSDKVersion() {
    XCTAssertEqual(
        CrashHandler.getFBSDKVersion(),
        Settings.sdkVersion
    )
  }

  func testGetCrashLogFileNames() {
    let files = [
      "crash_log_1576471375.json",
      "crash_lib_data_05DEDC8AFC724E09A5E68190C492B92B.json",
      "DATA_DETECTION_ADDRESS_1.weights",
      "SUGGEST_EVENT_3.weights",
      "SUGGEST_EVENT_3.rules",
      "crash.text"
    ]

    let result = crashHandler._getCrashLogFileNames(files)

    XCTAssertTrue(result.contains("crash_log_1576471375.json"))
    XCTAssertFalse(result.contains("crash_lib_data_05DEDC8AFC724E09A5E68190C492B92B.json"))
    XCTAssertFalse(result.contains("DATA_DETECTION_ADDRESS_1.weights"))
    XCTAssertFalse(result.contains("SUGGEST_EVENT_3.weights"))
    XCTAssertFalse(result.contains("SUGGEST_EVENT_3.rules"))
    XCTAssertFalse(result.contains("crash.text"))
  }

  func testGettingFileNamesFromEmptyList() {
    XCTAssertTrue(
        crashHandler._getCrashLogFileNames([]).isEmpty,
        "Should not get file names from an empty list of names"
    )
  }

  func testGetPathToCrashFile() {
    let timeStamp = "test_timestamp"
    let crashLogFileName = "crash_log_\(timeStamp).json"
    let pathToCrashFile = crashHandler._getPath(toCrashFile: timeStamp)

    XCTAssertTrue(pathToCrashFile.hasSuffix(crashLogFileName))
  }

  func testCallStackContainsPrefix() {
    let prefixList = ["FBSDK", "_FBSDK"]

    let callStack1 = [
      "(2 DEV METHODS)",
      "-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+2110632",
      "-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+10540",
      "(14 DEV METHODS)",
    ]

    XCTAssertTrue(
        crashHandler._callstack(callStack1, containsPrefix: prefixList),
        """
        A callstack should be considered to contain a prefix if the first
        item in the stack begins with any of the provided prefixes
        """
    )

    let callStack2 = [
      "(2 DEV METHODS)",
      "-[FBAdPersistentCacheImpl storeAssetInMemory:forKey:expiration:]+14455428",
      "(12 DEV METHODS)",
    ]

    XCTAssertFalse(
       crashHandler._callstack(callStack2, containsPrefix: prefixList),
       """
       A callstack should be considered to contain a prefix if the first
       item in the stack begins with any of the provided prefixes
       """
    )
  }

  func testLoadCrashLogs() {
    let fileName = "dance_with_animals.txt"
    crashHandler._loadCrashLog(fileName)
    guard let path = TestFileDataExtractor.capturedFileNames.first,
          path.contains("dance_with_animals.txt")
    else {
      XCTFail("Loading a crash log should check the provided path for crashlog data")
      return
      }
  }

  func testSaveCrashLogs() {
    crashHandler._saveCrashLog(self.processedCrashLogs()[0])
    XCTAssertEqual(testBundle.capturedKeys, ["CFBundleShortVersionString", "CFBundleVersion"])
  }

  func testFilterCrashLogs() {
    let filteredCrashLogs = crashHandler._filterCrashLogs(
    ["FBSDK", "_FBSDK"],
    processedCrashLogs: self.processedCrashLogs()
  )
    XCTAssertEqual(1, filteredCrashLogs.count)
  }

  func processedCrashLogs() -> [[String: Any]] {
    let crashLog1 = ["app_version": "4.16(4)",
                          "callstack": [
                            "(2 DEV METHODS)",
                            "-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+2110632",
                            "-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+10540",
                            "(14 DEV METHODS)",
                          ],
                          "reason": "InvalidOperationException",
                          "timestamp": "1585764970",
                          "device_model": "iPhone7,2",
                          "device_os_version": "12.4.1"] as [String: Any]

    let crashLog2 = ["app_version": "1.173.0(2)",
                     "callstack": [
                            "(3 DEV METHODS)",
                            "-[SettingsItemViewController imageWithImage:destination:]+2110632",
                            "(6 DEV METHODS)"],
                          "reason": "NSInvalidArgumentException",
                          "timestamp": "1585764970",
                          "device_model": "iPad4,1",
                          "device_os_version": "12.4.5"
    ] as [String: Any]

    return [crashLog1, crashLog2]
  }
}
