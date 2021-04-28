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
class TestURLSessionProxyFactory: NSObject, URLSessionProxyProviding {
  private var stubbedSessions: [TestURLSessionProxy]

  init(session: TestURLSessionProxy) {
    self.stubbedSessions = [session]
  }

  init(sessions: [TestURLSessionProxy]) {
    self.stubbedSessions = sessions
  }

  /// Creates a new provider stubbed with the `FakeURLSessionProxy`
  ///
  /// If you provide a single session, all calls to `createSessionProxy` will return the same
  /// session instance
  static func create(with session: TestURLSessionProxy) -> TestURLSessionProxyFactory {
    TestURLSessionProxyFactory(session: session)
  }

  /// Creates a new provider stubbed with the `FakeURLSessionProxy`
  ///
  /// If you provide multiple sessions, they will be provided in the order they are requested
  static func create(withSessions sessions: [TestURLSessionProxy]) -> TestURLSessionProxyFactory {
    TestURLSessionProxyFactory(sessions: sessions)
  }

  // MARK: - UrlSessionProxyProviding

  func createSessionProxy(with delegate: URLSessionDataDelegate?, queue: OperationQueue?) -> URLSessionProxying {
    return stubbedSessions.count > 1 ? stubbedSessions.removeFirst() : stubbedSessions[0]
  }
}
