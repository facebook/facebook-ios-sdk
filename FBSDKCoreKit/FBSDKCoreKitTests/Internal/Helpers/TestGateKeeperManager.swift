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
class TestGateKeeperManager: NSObject, GateKeeperManaging {
  static var gateKeepers = [String?: Bool]()
  static var loadGateKeepersWasCalled = false
  static var capturedLoadGateKeepersCompletion: GKManagerBlock?
  static var capturedBoolForGateKeeperKeys = [String]()

  static func setGateKeeperValue(key: String, value: Bool) {
    gateKeepers[key] = value
  }

  static func bool(forKey key: String, defaultValue: Bool) -> Bool {
    capturedBoolForGateKeeperKeys.append(key)
    if let value = gateKeepers[key] {
      return value
    } else {
      return defaultValue
    }
  }

  static func loadGateKeepers(_ completionBlock: @escaping GKManagerBlock) {
    loadGateKeepersWasCalled = true
    capturedLoadGateKeepersCompletion = completionBlock
  }

  static func reset() {
    gateKeepers = [:]
    loadGateKeepersWasCalled = false
    capturedLoadGateKeepersCompletion = nil
    capturedBoolForGateKeeperKeys = []
  }
}
