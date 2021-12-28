/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestLogger: Logger {
  static var capturedLoggingBehavior: LoggingBehavior?
  /// The most recent log entry
  static var capturedLogEntry: String?
  /// All log entries captured between resetting the fixture
  static var capturedLogEntries = [String]()

  let stubbedLoggingBehavior: LoggingBehavior

  override var contents: String {
    capturedContents ?? ""
  }

  var capturedAppendedKeys = [String]()
  var capturedAppendedValues = [String]()
  var stubbedIsActive = false
  var capturedContents: String?
  var logEntryCallCount = 0

  var capturedLoggingBehavior: LoggingBehavior?

  required init(loggingBehavior: LoggingBehavior) {
    stubbedLoggingBehavior = loggingBehavior

    super.init(loggingBehavior: loggingBehavior)
  }

  override class func singleShotLogEntry(_ loggingBehavior: LoggingBehavior, logEntry: String) {
    capturedLoggingBehavior = loggingBehavior
    capturedLogEntry = logEntry
    capturedLogEntries.append(logEntry)
  }

  override func logEntry(_ logEntry: String) {
    capturedContents = logEntry
    logEntryCallCount += 1
  }

  override var isActive: Bool {
    stubbedIsActive
  }

  override func appendKey(_ key: String, value: String) {
    capturedAppendedKeys.append(key)
    capturedAppendedValues.append(value)
  }

  class func reset() {
    capturedLoggingBehavior = nil
    capturedLogEntry = nil
    capturedLogEntries = []
  }
}
