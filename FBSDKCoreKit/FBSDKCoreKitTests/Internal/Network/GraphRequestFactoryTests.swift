/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class GraphRequestFactoryTests: XCTestCase {

  let factory = GraphRequestFactory()

  func testCreatingRequest() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "foo",
      httpMethod: .get,
      flags: [.skipClientToken, .disableErrorRecovery]
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: "foo",
      expectedVersion: "v16.0",
      expectedMethod: .get
    )
  }

  func testUseAlternative1() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      httpMethod: .post,
      useAlternativeDefaultDomainPrefix: false
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .post,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative2() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "test_token_string",
      httpMethod: .post,
      flags: [],
      forAppEvents: true,
      useAlternativeDefaultDomainPrefix: false
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: "test_token_string",
      expectedVersion: "v16.0",
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative3() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "test_token_string",
      httpMethod: .post,
      flags: [],
      useAlternativeDefaultDomainPrefix: false
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: "test_token_string",
      expectedVersion: "v16.0",
      expectedMethod: .post,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative4() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "test_token_string",
      version: "17.0",
      httpMethod: .post,
      forAppEvents: true,
      useAlternativeDefaultDomainPrefix: false
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: "test_token_string",
      expectedVersion: "17.0",
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative5() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      useAlternativeDefaultDomainPrefix: false
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .get,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative6() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      useAlternativeDefaultDomainPrefix: false
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["fields": ""],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .get,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternative7() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      flags: [],
      useAlternativeDefaultDomainPrefix: false
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .get,
      expectedUseAlternativeValue: false
    )
  }

  func testUseAlternativeDefaultValue1() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      httpMethod: .post
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .post,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue2() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "test_token_string",
      httpMethod: .post,
      flags: [],
      forAppEvents: true
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: "test_token_string",
      expectedVersion: "v16.0",
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue3() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "test_token_string",
      httpMethod: .post,
      flags: []
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: "test_token_string",
      expectedVersion: "v16.0",
      expectedMethod: .post,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue4() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "test_token_string",
      version: "17.0",
      httpMethod: .post,
      forAppEvents: true
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: "test_token_string",
      expectedVersion: "17.0",
      expectedMethod: .post,
      expectedForAppEvents: true,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue5() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"]
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .get,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue6() {
    let request = factory.createGraphRequest(
      withGraphPath: "me"
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["fields": ""],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .get,
      expectedUseAlternativeValue: true
    )
  }

  func testUseAlternativeDefaultValue7() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      flags: []
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }
    GraphRequestTests.verifyRequest(
      graphRequest,
      expectedGraphPath: "me",
      expectedParameters: ["some": "thing"],
      expectedTokenString: nil,
      expectedVersion: "v16.0",
      expectedMethod: .get,
      expectedUseAlternativeValue: true
    )
  }
}
