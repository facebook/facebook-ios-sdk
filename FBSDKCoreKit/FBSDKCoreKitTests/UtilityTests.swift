/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class UtilityTests: XCTestCase {
  func testSHA256Hash() {
    let hashed = Utility.sha256Hash("facebook" as NSObject)

    XCTAssertEqual(hashed, "3d59f7548e1af2151b64135003ce63c0a484c26b9b8b166a7b1c1805ec34b00a")
  }

  func testURLDecodeShouldNotModifyUnencodedURLString() {
    let unencoded = "https://www.facebook.com/index.html?a=b&c=d"

    XCTAssertEqual(unencoded, Utility.decode(urlString: unencoded))
  }

  func testURLEncode() {
    let unencoded = "https://www.facebook.com/index.html?a=b&c=d"
    let encoded = "https%3A%2F%2Fwww.facebook.com%2Findex.html%3Fa%3Db%26c%3Dd"

    XCTAssertEqual(encoded, Utility.encode(urlString: unencoded))
    XCTAssertEqual(unencoded, Utility.decode(urlString: encoded))
  }

  func testURLEncodeWithJSON() {
    let url = "https://m.facebook.com/v3.2/dialog/oauth?auth_type=rerequest&client_id=123456789&default_audience=friends&display=touch&e2e={\"init\":123456.1234567890}&fbapp_pres=0&redirect_uri=fb111111111111111://authorize/&response_type=token,signed_request&return_scopes=true&scope=&sdk=ios&sdk_version=4.39.0&state={\"challenge\":\"aBcDeFghiJKlmnOpQRS%tU\",\"0_auth_logger_id\":\"01234ABC-12AB-34DE-1234-ABCDEFG12345\",\"com.facebook.some_identifier\":true,\"3_method\":\"sfvc_auth\"}" // swiftlint:disable:this line_length
    let encoded = "https%3A%2F%2Fm.facebook.com%2Fv3.2%2Fdialog%2Foauth%3Fauth_type%3Drerequest%26client_id%3D123456789%26default_audience%3Dfriends%26display%3Dtouch%26e2e%3D%7B%22init%22%3A123456.1234567890%7D%26fbapp_pres%3D0%26redirect_uri%3Dfb111111111111111%3A%2F%2Fauthorize%2F%26response_type%3Dtoken%2Csigned_request%26return_scopes%3Dtrue%26scope%3D%26sdk%3Dios%26sdk_version%3D4.39.0%26state%3D%7B%22challenge%22%3A%22aBcDeFghiJKlmnOpQRS%25tU%22%2C%220_auth_logger_id%22%3A%2201234ABC-12AB-34DE-1234-ABCDEFG12345%22%2C%22com.facebook.some_identifier%22%3Atrue%2C%223_method%22%3A%22sfvc_auth%22%7D" // swiftlint:disable:this line_length
    XCTAssertEqual(encoded, Utility.encode(urlString: url))
    XCTAssertEqual(url, Utility.decode(urlString: encoded))
  }

  @available(iOS, deprecated: 9.0)
  func testNewEncodeWorksLikeLegacy() {
    for num in 0 ..< 256 {
      let str = String(Character(UnicodeScalar(num)!)) // swiftlint:disable:this force_unwrapping
      if str == "{" || str == "}" {
        continue // Curly braces were not included in legacy URL encode
      }
      XCTAssertEqual(Utility.encode(urlString: str), legacyURLEncode(str))
    }
  }

  @available(iOS, deprecated: 9.0) // Needed to disable warning on CFURLCreateStringByAddingPercentEscapes
  func legacyURLEncode(_ value: String) -> String? {
    CFURLCreateStringByAddingPercentEscapes(
      nil,
      value as CFString,
      nil,
      ":!*();@/&?+$,='" as CFString,
      CFStringBuiltInEncodings.UTF8.rawValue
    ) as String
  }
}
