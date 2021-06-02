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
class TestTimeSpentRecorder: NSObject, SourceApplicationTracking, TimeSpentRecording {

  // swiftlint:disable identifier_name
  var restoreWasCalled = false
  var suspendWasCalled = false
  var capturedCalledFromActivateApp = false
  var capturedSetSourceApplication: String?
  var capturedSetSourceApplicationURL: URL?
  var capturedSetSourceApplicationFromAppLink: String?
  var capturedIsFromAppLink = false
  var wasRegisterAutoResetSourceApplicationCalled = false

  func suspend() {
    suspendWasCalled = true
  }

  func restore(_ calledFromActivateApp: Bool) {
    restoreWasCalled = true
    capturedCalledFromActivateApp = calledFromActivateApp
  }

  func setSourceApplication(_ sourceApplication: String?, open url: URL?) {
    capturedSetSourceApplication = sourceApplication
    capturedSetSourceApplicationURL = url
  }

  func setSourceApplication(_ sourceApplication: String?, isFromAppLink: Bool) {
    capturedSetSourceApplicationFromAppLink = sourceApplication
    capturedIsFromAppLink = isFromAppLink
  }

  func registerAutoResetSourceApplication() {
    wasRegisterAutoResetSourceApplicationCalled = true
  }
}
