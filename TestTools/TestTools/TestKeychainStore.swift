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

@objcMembers
public class TestKeychainStore: NSObject, KeychainStoreProtocol {
  public var service: String?
  public var accessGroup: String?
  public var wasStringForKeyCalled = false
  public var wasSetStringCalled = false
  public var value: String?
  public var key: String?
  public var keychainDictionary: [String: String] = [:]
  public var wasDictionaryForKeyCalled = false
  public var wasSetDictionaryCalled = false

  public convenience init(
    service: String,
    accessGroup: String?
  ) {
    self.init()
    self.service = service
    self.accessGroup = accessGroup
  }

  public func string(forKey key: String) -> String? {
    wasStringForKeyCalled = true
    return keychainDictionary[key]
  }

  public func setString(_ value: String?, forKey key: String, accessibility: CFTypeRef?) -> Bool {
    keychainDictionary[key] = value
    wasSetStringCalled = true
    return true
  }

  public func dictionary(forKey key: String) -> [String: Any]? {
    wasDictionaryForKeyCalled = true
    return [:]
  }

  public func setDictionary(_ value: [String: Any]?, forKey key: String, accessibility: CFTypeRef?) -> Bool {
    wasSetDictionaryCalled = true
    return true
  }
}
