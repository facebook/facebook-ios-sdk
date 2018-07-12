// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import FBSDKCoreKit.FBSDKGraphRequest
import Foundation

extension GraphRequestProtocol {
  internal var sdkRequest: FBSDKGraphRequest {
    // TODO: (nlutsenko) Consider constraining `parameters` for specific types aka create `GraphRequestParameterValue`
    let sdkParameters: [String: Any]? = parameters?.keyValueMap { key, value in
      if let value = value as? GraphRequestDataAttachment {
        return (key, value.sdkDataAttachment)
      }
      return (key, value)
    }

    // ObjC SDK requires `v` as a prefix for the Graph API Version.
    let apiVersion = "v" + self.apiVersion.stringValue
    return FBSDKGraphRequest(graphPath: graphPath,
                             parameters: sdkParameters,
                             tokenString: accessToken?.authenticationToken,
                             version: apiVersion,
                             httpMethod: httpMethod.rawValue)
  }
}
