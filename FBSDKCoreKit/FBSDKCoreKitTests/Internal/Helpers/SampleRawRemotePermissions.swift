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
public class SampleRawRemotePermissionList: NSObject {

  @objc
  public static var missingPermissions: [String: Any] {
    [
      "data": [
        [
          "permission": nil,
          "status": "granted"
        ],
        [
          "permission": nil,
          "status": "declined"
        ],
        [
          "permission": nil,
          "status": "expired"
        ]
      ]
    ]
  }

  @objc
  public static var missingStatus: [String: Any] {
    [
      "data": [
        [
          "permission": "email",
          "status": nil
        ]
      ]
    ]
  }

  @objc
  public static let missingTopLevelKey: [String: Any] = [:]

  @objc
  public static var randomValues: Any {
    let json: Any = [
      "data": [
        [
          "permission": "foo",
          "status": "granted"
        ]
      ]
    ]
    return Fuzzer.randomize(json: json)
  }

  @objc
  public static var validAllStatuses: [String: Any] {
    [
      "data": [
        [
          "permission": "email",
          "status": "granted"
        ],
        [
          "permission": "birthday",
          "status": "declined"
        ],
        [
          "permission": "first_name",
          "status": "expired"
        ]
      ]
    ]
  }

  @objc
  public static func with(
    granted: [String] = [],
    declined: [String] = [],
    expired: [String] = []
  ) -> [String: Any] {
    let grantedPermissions = granted.map {
      return [
        "permission": $0,
        "status": "granted"
      ]
    }
    let declinedPermissions = declined.map {
      return [
        "permission": $0,
        "status": "declined"
      ]
    }
    let expiredPermissions = expired.map {
      return [
        "permission": $0,
        "status": "expired"
      ]
    }
    return ["data": grantedPermissions + expiredPermissions + declinedPermissions]
  }

}

@objc public class SampleRawRemotePermission: NSObject {

  @objc public static let missingTopLevelKey: [String: Any] = [:]
}
