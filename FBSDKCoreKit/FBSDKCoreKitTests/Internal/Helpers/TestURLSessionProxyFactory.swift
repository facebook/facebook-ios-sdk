/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestURLSessionProxyFactory: NSObject, URLSessionProxyProviding {
  private var stubbedSessions: [TestURLSessionProxy]

  init(sessions: [TestURLSessionProxy] = []) {
    stubbedSessions = sessions
  }

  /// Creates a new provider stubbed with the `FakeURLSessionProxy`
  ///
  /// If you provide a single session, all calls to `createSessionProxy` will return the same
  /// session instance
  static func create(with session: TestURLSessionProxy) -> TestURLSessionProxyFactory {
    TestURLSessionProxyFactory(sessions: [session])
  }

  /// Creates a new provider stubbed with the `FakeURLSessionProxy`
  ///
  /// If you provide multiple sessions, they will be provided in the order they are requested
  static func create(withSessions sessions: [TestURLSessionProxy]) -> TestURLSessionProxyFactory {
    TestURLSessionProxyFactory(sessions: sessions)
  }

  // MARK: - URLSessionProxyProviding

  func createSessionProxy(with delegate: URLSessionDataDelegate?, queue: OperationQueue?) -> URLSessionProxying {
    stubbedSessions.count > 1 ? stubbedSessions.removeFirst() : stubbedSessions[0]
  }
}
