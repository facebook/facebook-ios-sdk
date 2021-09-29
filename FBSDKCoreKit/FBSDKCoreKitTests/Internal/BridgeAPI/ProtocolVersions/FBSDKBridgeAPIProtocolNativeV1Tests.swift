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
import Foundation

// swiftlint:disable type_body_length
class FBSDKBridgeAPIProtocolNativeV1Tests: XCTestCase {
  let actionID = UUID().uuidString
  let scheme = UUID().uuidString
  let methodName = UUID().uuidString
  let methodVersion = UUID().uuidString
  lazy var protocolNativeV1 = BridgeAPIProtocolNativeV1(appScheme: scheme)
  // swiftlint:enable force_unwrapping
  let pasteboard = TestPasteboard()

  func testRequestURL() {
    let parameters = [
      "api_key_1": "value1",
      "api_key_2": "value2"
    ]

    do {
      let requestURL = try protocolNativeV1.requestURL(
        withActionID: actionID,
        scheme: scheme,
        methodName: methodName,
        methodVersion: methodVersion,
        parameters: parameters
      )

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix))

      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args", "version"])
      XCTAssertEqual(Set(queryParameters.keys), expectedKeys)
      do {
        let basicParameters = try BasicUtility.object(forJSONString: queryParameters["method_args", default: ""])
        XCTAssertEqual(basicParameters as? [String: String], parameters)
      } catch {
        XCTFail("Unexpected error thrown: \(error)")
      }
    } catch {
      XCTFail("Unexpected error thrown: \(error)")
    }
  }

  func testNilResponseParameters() {
    var cancelled: ObjCBool = true

    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: [:],
        cancelled: &cancelled
      )
      XCTAssertNil(response)
    } catch {
      XCTAssertNotNil(error)
    }
    XCTAssertFalse(cancelled.boolValue)

    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: [:],
        cancelled: &cancelled
      )
      XCTAssertNil(response)
    } catch {
      XCTAssertNotNil(error)
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testEmptyResponseParameters() {
    var cancelled: ObjCBool = true
    var queryParameters: [String: Any] = [
      "bridge_args": [
        "action_id": actionID
      ],
      "method_results": [:]
    ]
    queryParameters = stubEncodeQueryParameters(queryParameters)

    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: [:],
        cancelled: &cancelled
      )

      XCTAssertEqual(response as? [String: String], [:])
    } catch {
      XCTAssertNotNil(error)
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testResponseParameters() {
    var cancelled: ObjCBool = true
    let responseParameters: [String: Any] = [
      "result_key_1": 1,
      "result_key_2": "two",
      "result_key_3": [
        "result_key_4": 4,
        "result_key_5": "five"
      ]
    ]
    var queryParameters: [String: Any] = [
      "bridge_args": [
        "action_id": actionID
      ],
      "method_results": responseParameters
    ]
    queryParameters = stubEncodeQueryParameters(queryParameters)

    do {
      let response: [String: Any] = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: queryParameters,
        cancelled: &cancelled
      )
      XCTAssertEqual(response as NSObject, responseParameters as NSObject)
    } catch {
      XCTFail("Unexpected error thrown: \(error)")
    }
  }

  func testInvalidActionID() {
    var cancelled: ObjCBool = true
    let responseParameters: [String: Any] = [
      "result_key_1": 1,
      "result_key_2": "two",
      "result_key_3": [
        "result_key_4": 4,
        "result_key_5": "five"
      ]
    ]
    var queryParameters: [String: Any] = [
      "bridge_args": [
        "action_id": UUID().uuidString
      ],
      "method_results": responseParameters
    ]
    queryParameters = stubEncodeQueryParameters(queryParameters)
    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: [:],
        cancelled: &cancelled
      )
      XCTAssertNil(response)
    } catch {
      XCTAssertNotNil(error)
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testInvalidBridgeArgs() {
    var cancelled: ObjCBool = true

    let bridgeArgs = "this is an invalid bridge_args value"
    var queryParameters: [String: Any] = [
      "bridge_args": bridgeArgs,
      "method_results": [
        "result_key_1": 1,
        "result_key_2": "two"
      ]
    ]
    queryParameters = stubEncodeQueryParameters(queryParameters)
    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: queryParameters,
        cancelled: &cancelled
      )
      XCTAssertNil(response)
    } catch {
      guard let error = error as NSError? else { XCTFail("Error is not an NSError") }
      XCTAssertNotNil(error)
      XCTAssertEqual(error.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(error.domain, ErrorDomain)
      XCTAssertEqual(error.userInfo[ErrorArgumentNameKey] as? String, "bridge_args")
      XCTAssertEqual(error.userInfo[ErrorArgumentValueKey] as? String, bridgeArgs)
      XCTAssertNotNil(error.userInfo[ErrorDeveloperMessageKey])
      XCTAssertNotNil(error.userInfo[NSUnderlyingErrorKey])
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testInvalidMethodResults() {
    var cancelled: ObjCBool = true

    let methodResults = "this is an invalid method_results value"
    var queryParameters: [String: Any] = [
      "bridge_args": [
        "action_id": actionID
      ],
      "method_results": methodResults
    ]
    queryParameters = stubEncodeQueryParameters(queryParameters)
    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: queryParameters,
        cancelled: &cancelled
      )
      XCTAssertNil(response)
    } catch {
      guard let error = error as NSError? else { XCTFail("Error is not an NSError") }
      XCTAssertNotNil(error)
      XCTAssertEqual(error.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(error.domain, ErrorDomain)
      XCTAssertEqual(error.userInfo[ErrorArgumentNameKey] as? String, "method_results")
      XCTAssertEqual(error.userInfo[ErrorArgumentValueKey] as? String, methodResults)
      XCTAssertNotNil(error.userInfo[ErrorDeveloperMessageKey])
      XCTAssertNotNil(error.userInfo[NSUnderlyingErrorKey])
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testResultError() {
    var cancelled: ObjCBool = true

    let code = 42
    let domain = "my custom error domain"
    let userInfo: [String: Any] = [
      "key_1": 1,
      "key_2": "two"
    ]
    var queryParameters: [String: Any] = [
      "bridge_args": [
        "action_id": actionID,
        "error": [
          "code": code,
          "domain": domain,
          "user_info": userInfo
        ]
      ],
      "method_results": [
        "result_key_1": 1,
        "result_key_2": "two"
      ]
    ]
    queryParameters = stubEncodeQueryParameters(queryParameters)
    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: queryParameters,
        cancelled: &cancelled
      )
      XCTAssertNil(response)
    } catch {
      guard let error = error as NSError? else { XCTFail("Error is not an NSError") }
      XCTAssertNotNil(error)
      XCTAssertEqual(error.code, code)
      XCTAssertEqual(error.domain, domain)
      XCTAssertEqual(error.userInfo as NSObject?, userInfo as NSObject)
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testResultCancel() {
    var cancelled: ObjCBool = false

    var queryParameters: [String: Any] = [
      "bridge_args": [
        "action_id": actionID
      ],
      "method_results": [
        "completionGesture": "cancel"
      ]
    ]
    queryParameters = stubEncodeQueryParameters(queryParameters)
    do {
      let response = try protocolNativeV1.responseParameters(
        forActionID: actionID,
        queryParameters: queryParameters,
        cancelled: &cancelled
      )
      XCTAssertNotNil(response)
    } catch {
      XCTFail("Unexpected error thrown: \(error)")
    }
    XCTAssertTrue(cancelled.boolValue)
  }

  func testRequestParametersWithDataJSON() {
    let protocolNative = BridgeAPIProtocolNativeV1(
      appScheme: scheme,
      pasteboard: nil,
      dataLengthThreshold: UInt.max,
      includeAppIcon: false
    )

    let parameters: [String: Any] = [
      "api_key_1": "value1",
      "api_key_2": "value2",
      "data": stubData()
    ]

    do {
      let requestURL = try protocolNative.requestURL(
        withActionID: actionID,
        scheme: scheme,
        methodName: methodName,
        methodVersion: methodVersion,
        parameters: parameters
      )

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args", "version"])
      XCTAssertEqual(Set(queryParameters.keys), expectedKeys)
      var expectedMethodArgs = parameters
      expectedMethodArgs["data"] = stubDataSerialized(parameters["data"] as? Data)

      do {
        let methodArgs = try BasicUtility.object(forJSONString: queryParameters["method_args"] ?? "") as? [String: Any]
        XCTAssertEqual(methodArgs as NSObject?, expectedMethodArgs as NSObject)
        if let parseMethodData = methodArgs?["data"] as? [String: Any], // swiftlint:disable:next indentation_width
           let decodedData = parseMethodData["fbAppBridgeType_jsonReadyValue"] {
          let baseDecodedData = Base64.decode(asData: decodedData as? String)
          XCTAssertNotNil(baseDecodedData)
          XCTAssertEqual(baseDecodedData, parameters["data"] as? Data)
        } else {
          XCTFail("Failed to parse method arguments")
        }
      } catch {
        XCTFail("Unexpected error thrown: \(error)")
      }
    } catch {
      XCTFail("Unexpected error thrown: \(error)")
    }
  }

  func testRequestParametersWithImageJSON() {
    let protocolNative = BridgeAPIProtocolNativeV1(
      appScheme: scheme,
      pasteboard: nil,
      dataLengthThreshold: UInt.max,
      includeAppIcon: false
    )

    let parameters: [String: Any] = [
      "api_key_1": "value1",
      "api_key_2": "value2",
      "image": stubImage()
    ]

    do {
      let requestURL = try protocolNative.requestURL(
        withActionID: actionID,
        scheme: scheme,
        methodName: methodName,
        methodVersion: methodVersion,
        parameters: parameters
      )

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args", "version"])
      XCTAssertEqual(Set(queryParameters.keys), expectedKeys)
      var expectedMethodArgs = parameters
      expectedMethodArgs["image"] = stubImageSerialized(parameters["image"] as? UIImage)
      do {
        let methodArgs = try BasicUtility.object(
          forJSONString: queryParameters["method_args"] ?? "") as? [String: Any]
        XCTAssertEqual(methodArgs as NSObject?, expectedMethodArgs as NSObject)
        if let parseMethodData = methodArgs?["image"] as? [String: Any], // swiftlint:disable:next indentation_width
           let decodedData = parseMethodData["fbAppBridgeType_jsonReadyValue"] {
          guard let baseDecodedData = Base64.decode(asData: decodedData as? String) else {
            return XCTAssertNil("Failed to decode data from Base64")
          }
          XCTAssertNotNil(UIImage(data: baseDecodedData))
        } else {
          XCTFail("Failed to parse method arguments")
        }
      } catch {
        XCTFail("Unexpected error thrown: \(error)")
      }
    } catch {
      XCTFail("Unexpected error thrown: \(error)")
    }
  }

  func testRequestParametersWithDataPasteboard() {
    let pasteboardName = UUID().uuidString
    pasteboard.name = pasteboardName
    let data = stubData()

    let protocolNative = BridgeAPIProtocolNativeV1(
      appScheme: scheme,
      pasteboard: pasteboard,
      dataLengthThreshold: 0,
      includeAppIcon: false
    )

    let parameters: [String: Any] = [
      "api_key_1": "value1",
      "api_key_2": "value2",
      "data": data
    ]

    do {
      let requestURL = try protocolNative.requestURL(
        withActionID: actionID,
        scheme: scheme,
        methodName: methodName,
        methodVersion: methodVersion,
        parameters: parameters
      )

      XCTAssertEqual(pasteboard.capturedData, data as Data?)
      XCTAssertEqual(pasteboard.capturedPasteboardType, "com.facebook.Facebook.FBAppBridgeType")

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args", "version"])
      XCTAssertEqual(Set(queryParameters.keys), expectedKeys)
      var expectedMethodArgs = parameters
      expectedMethodArgs["data"] = stubDataContainer(withPasteboardName: pasteboardName, tag: "data")
      do {
        let methodArgs = try BasicUtility.object(
          forJSONString: queryParameters["method_args"] ?? "") as? [String: Any]
        XCTAssertEqual(methodArgs as NSObject?, expectedMethodArgs as NSObject)
      } catch {
        XCTFail("Unexpected error thrown: \(error)")
      }
    } catch {
      XCTFail("Unexpected error thrown: \(error)")
    }
  }

  func testRequestParametersWithImagePasteboard() {
    let pasteboardName = UUID().uuidString
    pasteboard.name = pasteboardName
    let image = stubImage()
    let data = stubData(with: image)

    let protocolNative = BridgeAPIProtocolNativeV1(
      appScheme: scheme,
      pasteboard: pasteboard,
      dataLengthThreshold: 0,
      includeAppIcon: false
    )

    let parameters: [String: Any] = [
      "api_key_1": "value1",
      "api_key_2": "value2",
      "image": image
    ]

    do {
      let requestURL = try protocolNative.requestURL(
        withActionID: actionID,
        scheme: scheme,
        methodName: methodName,
        methodVersion: methodVersion,
        parameters: parameters
      )

      XCTAssertEqual(pasteboard.capturedData, data as Data?)
      XCTAssertEqual(pasteboard.capturedPasteboardType, "com.facebook.Facebook.FBAppBridgeType")

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args", "version"])
      XCTAssertEqual(Set(queryParameters.keys), expectedKeys)
      var expectedMethodArgs = parameters
      expectedMethodArgs["image"] = stubDataContainer(withPasteboardName: pasteboardName, tag: "png")
      do {
        let methodArgs = try BasicUtility.object(
          forJSONString: queryParameters["method_args"] ?? "") as? [String: Any]
        XCTAssertEqual(methodArgs as NSObject?, expectedMethodArgs as NSObject)
      } catch {
        XCTFail("Unexpected error thrown: \(error)")
      }
    } catch {
      XCTFail("Unexpected error thrown: \(error)")
    }
  }

  // MARK: - Helpers

  func stubEncodeQueryParameters(_ queryParameters: [String: Any]) -> [String: Any] {
    let encoded = [:] as NSMutableDictionary
    for (key, value) in queryParameters {
      do {
        try BasicUtility.dictionary(
          encoded,
          setJSONStringFor: value,
          forKey: key as NSCopying
        )
      } catch {
        TypeUtility.dictionary(
          encoded,
          setObject: value,
          forKey: key as NSCopying
        )
      }
    }
    return encoded as? [String: Any] ?? [:]
  }

  func stubData() -> NSMutableData {
    if let data = NSMutableData(length: 1024) {
      arc4random_buf(data.mutableBytes, data.count)
      return data
    }
    return NSMutableData()
  }

  func stubDataContainer(withPasteboardName pasteboardName: String?, tag: String?) -> [String: Any]? {
    [
      "isPasteboard": NSNumber(value: true),
      "tag": tag ?? "",
      "fbAppBridgeType_jsonReadyValue": pasteboardName ?? ""
    ]
  }

  func stubDataSerialized(_ data: Data?) -> [String: Any]? {
    stubDataSerialized(data, tag: "data")
  }

  func stubDataSerialized(_ data: Data?, tag: String?) -> [String: Any]? {
    guard let string = Base64.encode(data) else { return nil }

    return [
      "isBase64": NSNumber(value: true),
      "tag": tag ?? "",
      "fbAppBridgeType_jsonReadyValue": string
    ]
  }

  func stubData(with image: UIImage?) -> Data? {
    image?.jpegData(compressionQuality: Settings.shared.jpegCompressionQuality)
  }

  func stubImage() -> UIImage {
    UIGraphicsBeginImageContext(CGSize(width: 10.0, height: 10.0))
    let context = UIGraphicsGetCurrentContext()
    UIColor.red.setFill()
    context?.fill(CGRect(x: 0.0, y: 0.0, width: 5.0, height: 5.0))
    UIColor.green.setFill()
    context?.fill(CGRect(x: 5.0, y: 0.0, width: 5.0, height: 5.0))
    UIColor.blue.setFill()
    context?.fill(CGRect(x: 5.0, y: 5.0, width: 5.0, height: 5.0))
    UIColor.yellow.setFill()
    context?.fill(CGRect(x: 0.0, y: 5.0, width: 5.0, height: 5.0))
    let imageRef = context?.makeImage()
    UIGraphicsEndImageContext()
    var image = UIImage()
    if let imageRef: CGImage = imageRef {
      image = UIImage(cgImage: imageRef)
    }
    return image
  }

  func stubImageSerialized(_ image: UIImage?) -> [String: Any]? {
    let data = stubData(with: image)
    return stubDataSerialized(data, tag: "png")
  }
} // swiftlint:disable:this file_length
