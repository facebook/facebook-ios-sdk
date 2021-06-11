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
class TestBridgeApiResponseFactory: NSObject, BridgeAPIResponseCreating {

  var capturedResponseURL: URL?
  var capturedSourceApplication: String?
  var stubbedResponse: BridgeAPIResponse?
  var shouldFailCreation = false

  func createResponseCancelled(withRequest request: FBSDKBridgeAPIRequestProtocol) -> BridgeAPIResponse {
    stubbedResponse ?? createResponse(request: request, cancelled: true)
  }

  func createResponse(
    withRequest request: FBSDKBridgeAPIRequestProtocol,
    error: Error
  ) -> BridgeAPIResponse {
    stubbedResponse ?? createResponse(request: request, error: error)
  }

  func createResponse(
    withRequest request: FBSDKBridgeAPIRequestProtocol,
    responseURL: URL,
    sourceApplication: String?
  ) throws -> BridgeAPIResponse {
    capturedResponseURL = responseURL
    capturedSourceApplication = sourceApplication

    guard !shouldFailCreation else {
      throw CoreError(.errorBridgeAPIResponse)
    }

    return stubbedResponse ?? createResponse(request: request)
  }

  private func createResponse(
    request: FBSDKBridgeAPIRequestProtocol,
    error: Error? = nil,
    cancelled: Bool = false
  ) -> BridgeAPIResponse {
    BridgeAPIResponse(
      request: request,
      responseParameters: [:],
      cancelled: cancelled,
      error: error
    )
  }
}
