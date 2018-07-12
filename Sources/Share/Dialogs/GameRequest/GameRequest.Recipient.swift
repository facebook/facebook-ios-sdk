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

public extension GameRequest {
  /**
   Represents a recipient for a game request.
   */
  enum Recipient: Hashable {
    /**
     The Facebook user ID of the recipient.
     */
    case userId(String)

    /// The username of the recipient.
    case username(String)

    /// An invite token describing the recipient.
    case inviteToken(String)

    internal var rawValue: String {
      switch self {
      case .userId(let userId): return userId
      case .username(let username): return username
      case .inviteToken(let inviteToken): return inviteToken
      }
    }

    /// Calculate the hash of this `Recipient.`
    public var hashValue: Int {
      switch self {
      case .userId(let userId): return userId.hashValue
      case .username(let username): return username.hashValue
      case .inviteToken(let inviteToken): return inviteToken.hashValue
      }
    }

    /**
     Compare two `Recipient`s for equality.

     - parameter lhs: The first recipient to compare.
     - parameter rhs: The second recipient to compare.

     - returns: Whether or not the recipients are equal.
     */
    public static func == (lhs: GameRequest.Recipient, rhs: GameRequest.Recipient) -> Bool {
      switch (lhs, rhs) {
      case let (.userId(lhs), .userId(rhs)): return lhs == rhs
      case let (.username(lhs), .username(rhs)): return lhs == rhs
      case let (.inviteToken(lhs), .inviteToken(rhs)): return lhs == rhs
      default: return false
      }
    }
  }
}
