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

// Hacky subclassing to get around init not being available.
// Future work should update ServerConfigurationProvider to return
// a true abstraction instead of a concrete ServerConfiguration and this
// type should simply conform to that abstraction.
class TestServerConfiguration: ServerConfiguration {
  var capturedUseNativeDialogName: String?
  var capturedUseSafariControllerName: String?
  var stubbedDefaultShareMode: String?
  @objc var stubbedIsCodelessEventsEnabled = false

  @objc
  convenience init(
    appID: String = "123"
  ) {
    self.init(
      appID: appID,
      appName: nil,
      loginTooltipEnabled: true,
      loginTooltipText: nil,
      defaultShareMode: nil,
      advertisingIDEnabled: false,
      implicitLoggingEnabled: false,
      implicitPurchaseLoggingEnabled: false,
      codelessEventsEnabled: false,
      uninstallTrackingEnabled: false,
      dialogConfigurations: [:],
      dialogFlows: [:],
      timestamp: Date(),
      errorConfiguration: nil,
      sessionTimeoutInterval: 1,
      defaults: false,
      loggingToken: nil,
      smartLoginOptions: .enabled,
      smartLoginBookmarkIconURL: nil,
      smartLoginMenuIconURL: nil,
      updateMessage: nil,
      eventBindings: nil,
      restrictiveParams: nil,
      aamRules: nil,
      suggestedEventsSetting: nil
    )
  }

  override var isCodelessEventsEnabled: Bool {
    stubbedIsCodelessEventsEnabled
  }

  override var defaultShareMode: String? {
    stubbedDefaultShareMode
  }

  override func useNativeDialog(
    forDialogName dialogName: String?
  ) -> Bool {
    capturedUseNativeDialogName = dialogName
    return true
  }

  override func useSafariViewController(
    forDialogName dialogName: String?
  ) -> Bool {
    capturedUseSafariControllerName = dialogName
    return true
  }
}
