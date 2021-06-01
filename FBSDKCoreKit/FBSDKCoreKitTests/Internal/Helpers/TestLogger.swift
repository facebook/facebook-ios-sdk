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

@objcMembers
class TestLogger: Logger {
  static var capturedLoggingBehavior: LoggingBehavior?
  /// The most recent log entry
  static var capturedLogEntry: String?
  /// All log entries captured between resetting the fixture
  static var capturedLogEntries = [String]()

  let stubbedLoggingBehavior: LoggingBehavior

  override var contents: String {
    capturedContents
  }

  var capturedAppendedKeys = [String]()
  var capturedAppendedValues = [String]()
  var stubbedIsActive = false
  var capturedContents = ""

  var capturedLoggingBehavior: LoggingBehavior?

  required init(loggingBehavior: LoggingBehavior) {
    stubbedLoggingBehavior = loggingBehavior

    super.init(loggingBehavior: loggingBehavior)
  }

  override convenience init() {
    self.init(loggingBehavior: .developerErrors)
  }

  override class func singleShotLogEntry(_ loggingBehavior: LoggingBehavior, logEntry: String) {
    capturedLoggingBehavior = loggingBehavior
    capturedLogEntry = logEntry
    capturedLogEntries.append(logEntry)
  }

  override func logEntry(_ logEntry: String) {
    capturedContents = logEntry
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
