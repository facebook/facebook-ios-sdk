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

import Foundation

@objc
public class RawAppEventsConfigurationResponseFixtures: NSObject {

  enum Keys {
    static let defaultATEStatus = "default_ate_status"
    static let advertiserIDCollectionEnabled = "advertiser_id_collection_enabled"
    static let eventCollectionEnabled = "event_collection_enabled"
  }

  /// Provides a dictionary with well-known keys and random values for a network provided app events configuration
  @objc
  public class var random: [AnyHashable: Any] {
    return [
      Keys.defaultATEStatus: Fuzzer.random,
      Keys.advertiserIDCollectionEnabled: Fuzzer.random,
      Keys.eventCollectionEnabled: Fuzzer.random,
    ]
  }
}
