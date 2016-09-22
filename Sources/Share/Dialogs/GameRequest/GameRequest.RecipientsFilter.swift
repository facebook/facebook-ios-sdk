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

import FBSDKShareKit

extension GameRequest {
  /**
   Filter for who can be displayed in the multi-friend selector.
   */
  public struct RecipientsFilter: OptionSet {
    /// The raw value of the filter.
    public let rawValue: Int

    /**
     Initialize with a raw value for filter.

     - parameter rawValue: The raw value for the filter.
     */
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Friends using the app cannot be displayed.
    public static let hideUsers = RecipientsFilter(rawValue: 1 << 0)

    /// Friends not using the app cannot be displayed.
    public static let hideNonUsers = RecipientsFilter(rawValue: 1 << 1)

    /// The default filter. Includes users and non-users.
    public static let none: RecipientsFilter = [ ]

    internal var sdkFilterRepresentation: FBSDKGameRequestFilter {
      if contains(.hideUsers) {
        return .appNonUsers
      }
      if contains(.hideNonUsers) {
        return .appUsers
      }
      return .none
    }
  }
}
