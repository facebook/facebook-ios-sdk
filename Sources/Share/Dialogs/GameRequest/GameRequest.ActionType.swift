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
   Additional context about the nature of the request.
   */
  public enum ActionType {
    /**
     Send action type: The user is sending an object to the friends.

     - parameter objectId: The Open Graph object ID of the object being sent.
     */
    case send(objectId: String)

    /**
     Ask for action type: The user is asking for an object from friends.

     - parameter objectId: The Open Graph object ID of the object being sent.
     */
    case askFor(objectId: String)

    /// Turn action type: It is the turn of the friends to play against the user in a match. (no object)
    case turn

    internal var sdkActionRepresentation: (FBSDKGameRequestActionType, String?) {
      switch self {
      case .send(let objectId): return (FBSDKGameRequestActionType.send, objectId)
      case .askFor(let objectId): return (FBSDKGameRequestActionType.askFor, objectId)
      case .turn: return (FBSDKGameRequestActionType.turn, nil)
      }
    }
  }
}
