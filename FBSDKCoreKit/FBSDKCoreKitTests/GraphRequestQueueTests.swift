/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import UIKit
import XCTest

final class GraphRequestQueueTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var connection: TestGraphRequestConnection!
  var connectionFactory: TestGraphRequestConnectionFactory!
  var graphRequestQueue: GraphRequestQueue!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    connection = TestGraphRequestConnection()
    connectionFactory = TestGraphRequestConnectionFactory(
      stubbedConnection: connection
    )
    GraphRequestQueue.sharedInstance().configure(
      graphRequestConnectionFactory: connectionFactory
    )
    graphRequestQueue = GraphRequestQueue.sharedInstance()
    super.setUp()
  }

  override func tearDown() {
    GraphRequestQueue.sharedInstance().reset()
    connectionFactory = nil
    super.tearDown()
  }

  func requestsAreEqual(request1: GraphRequestProtocol, request2: GraphRequestProtocol) -> Bool {
    if request1.graphPath != request2.graphPath {
      return false
    }
    guard let params1 = request1.parameters as? [String: String],
          let params2 = request2.parameters as? [String: String] else {
      return false
    }
    return (params1 == params2) && (request1.httpMethod == request2.httpMethod)
  }

  func requestMetadatasAreEqual(request1: GraphRequestMetadata, request2: GraphRequestMetadata) -> Bool {
    guard let request1BatchParams = request1.batchParameters as? [String: String],
          let request2BatchParams = request2.batchParameters as? [String: String] else {
      return false
    }
    if request1BatchParams != request2BatchParams {
      return false
    }
    return requestsAreEqual(request1: request1.request, request2: request2.request)
  }

  func makeTestRequest(
    graphPath: String = "test_endpoint",
    parameters: [String: Any] = ["first_key": "first_value"],
    httpMethod: HTTPMethod = .post
  ) -> GraphRequestProtocol {
    let request = TestGraphRequest(graphPath: graphPath, parameters: parameters, httpMethod: httpMethod)
    return request
  }

  func makeTestRequestMetadata(
    graphPath: String = "test_endpoint",
    requestParameters: [String: Any] = ["first_key": "first_value"],
    httpMethod: HTTPMethod = .post,
    batchParameters: [String: Any] = ["batch_key": "batch_value"]
  ) -> GraphRequestMetadata {
    let request = makeTestRequest(graphPath: graphPath, parameters: requestParameters, httpMethod: httpMethod)
    return GraphRequestMetadata(
      request: request,
      completionHandler: nil,
      batchParameters: batchParameters
    )
  }

  func testDefaultDependencies() {
    GraphRequestQueue.sharedInstance().reset()
    XCTAssertNil(
      graphRequestQueue.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
    guard let requestsQueue = graphRequestQueue.requestsQueue as? [GraphRequestMetadata] else {
      XCTFail("Graph request queue should be backed by an array of GraphRequestMetadata")
      return
    }
    XCTAssertTrue(
      requestsQueue.isEmpty,
      "Should have an empty queue by default"
    )
  }

  func testQueueGraphRequestWithCompletion() {
    let testRequest = makeTestRequest()
    graphRequestQueue.enqueue(testRequest) { _, _, _ in }
    XCTAssertTrue(
      graphRequestQueue.requestsQueue.count == 1,
      "Queue should only have 1 request in it"
    )
    guard let requests = graphRequestQueue.requestsQueue as? [GraphRequestMetadata] else {
      XCTFail("Graph request queue should be backed by an array of GraphRequestMetadata")
      return
    }
    guard let queuedRequestMetadata = requests.first else {
      XCTFail("Graph request queue should have 1 request in it")
      return
    }
    XCTAssertTrue(
      requestsAreEqual(request1: testRequest, request2: queuedRequestMetadata.request),
      "Test request should equal queued request"
    )
  }

  func testQueueRequestMetadata() {
    let testRequestMetaData = makeTestRequestMetadata()
    graphRequestQueue.enqueue(testRequestMetaData)
    XCTAssertTrue(
      graphRequestQueue.requestsQueue.count == 1,
      "Queue should only have 1 request in it"
    )
    guard let requests = graphRequestQueue.requestsQueue as? [GraphRequestMetadata] else {
      XCTFail("Graph request queue should be backed by an array of GraphRequestMetadata")
      return
    }
    guard let queuedRequestMetadata = requests.first else {
      XCTFail("Graph request queue should have 1 request in it")
      return
    }
    XCTAssertTrue(
      requestMetadatasAreEqual(request1: testRequestMetaData, request2: queuedRequestMetadata),
      "Test request should equal queued request"
    )
  }

  func testQueueRequestsMetadata() {
    let testRequestMetaData1 = makeTestRequestMetadata()
    let testRequestMetaData2 = makeTestRequestMetadata(
      graphPath: "test_endpoint_2",
      requestParameters: ["second_key": "second_value"],
      httpMethod: .get
    )
    let requestsMetadata = [testRequestMetaData1, testRequestMetaData2]
    graphRequestQueue.enqueueRequests(requestsMetadata)
    XCTAssertTrue(
      graphRequestQueue.requestsQueue.count == 2,
      "Queue should have 2 requests in it"
    )
    guard let requests = graphRequestQueue.requestsQueue as? [GraphRequestMetadata] else {
      XCTFail("Graph request queue should be backed by an array of GraphRequestMetadata")
      return
    }
    for idx in requests.indices {
      if !requestMetadatasAreEqual(request1: requestsMetadata[idx], request2: requests[idx]) {
        XCTFail("Test request should equal queued request")
      }
    }
  }

  func testAllQueueing() {
    let request1 = makeTestRequest()
    let requestMetadata1 = makeTestRequestMetadata(requestParameters: ["param_key": "param_val"])
    let requestMetadata2 = makeTestRequestMetadata(graphPath: "test_endpoint_2", httpMethod: .get)
    let requestMetadata3 = makeTestRequestMetadata(
      graphPath: "test_endpoint_3",
      batchParameters: ["batch_key_1": "batch_value_1"]
    )
    let requestsMetadata = [requestMetadata2, requestMetadata3]
    graphRequestQueue.enqueue(request1) { _, _, _ in }
    graphRequestQueue.enqueue(requestMetadata1)
    graphRequestQueue.enqueueRequests(requestsMetadata)
    XCTAssertTrue(
      graphRequestQueue.requestsQueue.count == 4,
      "Queue should have 4 requests in it"
    )
    guard let requests = graphRequestQueue.requestsQueue as? [GraphRequestMetadata] else {
      XCTFail("Graph request queue should be backed by an array of GraphRequestMetadata")
      return
    }
    XCTAssertTrue(
      requestsAreEqual(request1: request1, request2: requests[0].request),
      "Test request should equal queued request"
    )
    XCTAssertTrue(
      requestMetadatasAreEqual(request1: requestMetadata1, request2: requests[1]),
      "Test request metadata should equal queued request metadata"
    )
    XCTAssertTrue(
      requestMetadatasAreEqual(request1: requestMetadata2, request2: requests[2]),
      "Test request metadata should equal queued request metadata"
    )
    XCTAssertTrue(
      requestMetadatasAreEqual(request1: requestMetadata3, request2: requests[3]),
      "Test request metadata should equal queued request metadata"
    )
  }

  func testFlush() {
    let requestMetadata1 = makeTestRequestMetadata()
    let requestMetadata2 = makeTestRequestMetadata(requestParameters: ["param_key": "param_val"])
    let requestMetadata3 = makeTestRequestMetadata(graphPath: "test_endpoint_2", httpMethod: .get)
    let requestMetadata4 = makeTestRequestMetadata(
      graphPath: "test_endpoint_3",
      batchParameters: ["batch_key_1": "batch_value_1"]
    )
    let requestsToQueue = [requestMetadata1, requestMetadata2, requestMetadata3, requestMetadata4]
    graphRequestQueue.enqueueRequests(requestsToQueue)
    XCTAssertTrue(
      graphRequestQueue.requestsQueue.count == 4,
      "Queue should have 4 requests in it before flush"
    )
    graphRequestQueue.flush()
    XCTAssertTrue(
      connection.startCallCount == 1,
      "GraphRequestConnection start should have been  called"
    )
    XCTAssertEqual(
      requestsToQueue.count,
      connection.capturedRequests.count,
      "Number of queued requests should eqaul number of GraphRequestConnection captured requests"
    )
    for idx in connection.capturedRequests.indices {
      if !requestsAreEqual(request1: requestsToQueue[idx].request, request2: connection.capturedRequests[idx]) {
        XCTFail("Queued request should eqaul GraphRequestConnection captured request")
      }
    }
    guard let requests = graphRequestQueue.requestsQueue as? [GraphRequestMetadata] else {
      XCTFail("Graph request queue should be backed by an array of GraphRequestMetadata")
      return
    }
    XCTAssertTrue(
      requests.isEmpty,
      "Queue should be empty after flush"
    )
  }
}
