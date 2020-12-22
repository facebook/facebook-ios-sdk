import Foundation

@objcMembers
class FakeGraphRequestConnection: NSObject, GraphRequestConnectionProviding {
  var startCallCount = 0
  var capturedGraphRequest: GraphRequest?
  var capturedCompletionHandler: GraphRequestBlock?

  func add(_ request: GraphRequest, completionHandler handler: @escaping GraphRequestBlock) {
    capturedGraphRequest = request
    capturedCompletionHandler = handler
  }

  func start() {
    startCallCount += 1
  }
}
