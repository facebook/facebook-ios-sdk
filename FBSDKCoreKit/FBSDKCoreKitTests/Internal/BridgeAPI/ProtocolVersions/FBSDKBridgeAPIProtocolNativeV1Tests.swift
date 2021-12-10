/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

// swiftlint:disable type_body_length
class FBSDKBridgeAPIProtocolNativeV1Tests: XCTestCase {
  let actionID = UUID().uuidString
  let scheme = UUID().uuidString
  let methodName = UUID().uuidString
  let methodVersion = UUID().uuidString
  let pasteboard = TestPasteboard()
  let errorFactory = TestErrorFactory()
  lazy var protocolNativeV1: BridgeAPIProtocolNativeV1 = {
    let bridgeProtocol = BridgeAPIProtocolNativeV1(appScheme: scheme)
    bridgeProtocol.errorFactory = errorFactory
    return bridgeProtocol
  }()

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
        parameters: parameters
      )

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix))

      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args"])
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

  func testInvalidBridgeArgs() throws {
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
      let error = try XCTUnwrap(error as? TestSDKError)
      XCTAssertEqual(error.type, .invalidArgument)
      XCTAssertEqual(error.code, TestSDKError.testErrorCode)
      XCTAssertEqual(error.domain, TestSDKError.testErrorDomain)
      XCTAssertEqual(error.name, "bridge_args")
      XCTAssertEqual(error.value as? String, bridgeArgs)
      XCTAssertNotNil(error.message)
      XCTAssertNotNil(error.underlyingError)
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testInvalidMethodResults() throws {
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
      let error = try XCTUnwrap(error as? TestSDKError)
      XCTAssertEqual(error.type, .invalidArgument)
      XCTAssertEqual(error.code, TestSDKError.testErrorCode)
      XCTAssertEqual(error.domain, TestSDKError.testErrorDomain)
      XCTAssertEqual(error.name, "method_results")
      XCTAssertEqual(error.value as? String, methodResults)
      XCTAssertNotNil(error.message)
      XCTAssertNotNil(error.underlyingError)
    }
    XCTAssertFalse(cancelled.boolValue)
  }

  func testResultError() throws {
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
      let error = try XCTUnwrap(error as? TestSDKError)
      XCTAssertEqual(error.code, code)
      XCTAssertEqual(error.domain, domain)
      XCTAssertEqual(error.userInfo["key_1"] as? Int, 1)
      XCTAssertEqual(error.userInfo["key_2"] as? String, "two")
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
      includeAppIcon: false,
      errorFactory: errorFactory
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
        parameters: parameters
      )

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args"])
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
      includeAppIcon: false,
      errorFactory: errorFactory
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
        parameters: parameters
      )

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args"])
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
      includeAppIcon: false,
      errorFactory: errorFactory
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
        parameters: parameters
      )

      XCTAssertEqual(pasteboard.capturedData, data as Data?)
      XCTAssertEqual(pasteboard.capturedPasteboardType, "com.facebook.Facebook.FBAppBridgeType")

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args"])
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
      includeAppIcon: false,
      errorFactory: errorFactory
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
        parameters: parameters
      )

      XCTAssertEqual(pasteboard.capturedData, data as Data?)
      XCTAssertEqual(pasteboard.capturedPasteboardType, "com.facebook.Facebook.FBAppBridgeType")

      let expectedPrefix = "\(scheme)://dialog/\(methodName)?"
      XCTAssertTrue(requestURL.absoluteString.hasPrefix(expectedPrefix) == true)
      /* Due to the non-deterministic order of Dictionary->JSON serialization,
       we cannot do string comparisons to verify. */
      let queryParameters = Utility.dictionary(withQuery: requestURL.query ?? "")
      let expectedKeys = Set(["bridge_args", "method_args"])
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
