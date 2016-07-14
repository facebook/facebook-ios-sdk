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

import Foundation
import FBSDKCoreKit

/**
 A container for data attachments so that additional metadata can be provided about the attachment (like content type or filename).
 */
public class GraphRequestDataAttachment {

  /// The attachment data.
  public let data: NSData

  /// The file name of the attachment.
  public let filename: String?

  /// The content type of the attachment.
  public let contentType: String?

  /**
   Initializes a data attachment

   - parameter data:        The attachment data (retained, not copied).
   - parameter filename:    Optional filename for the attachment. Default: `nil`.
   - parameter contentType: Optional content type for the attachment. Default: `nil`.
   */
  public init(data: NSData, filename: String? = nil, contentType: String? = nil) {
    self.data = data
    self.filename = filename
    self.contentType = contentType
  }
}

//--------------------------------------
// MARK: - Bridging
//--------------------------------------

extension GraphRequestDataAttachment {
  internal var sdkDataAttachment: FBSDKGraphRequestDataAttachment {
    return FBSDKGraphRequestDataAttachment(data: data, filename: filename, contentType: contentType)
  }
}
