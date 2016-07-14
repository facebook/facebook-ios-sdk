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

/**
 Specifies the type of object referenced by the objectID for likes.
 */
public enum LikableObject: Equatable {
  /// The objectId refers to an OpenGraph object.
  case OpenGraph(objectId: String)

  /// The objectId refers to a Page object.
  case Page(objectId: String)

  /**
   The objectId refers to an unknown object.

   The control will determine the object type by querying the server with the objectID.
   */
  case Unknown(objectId: String)
}

extension LikableObject {
  internal init(sdkObjectType: FBSDKLikeObjectType, sdkObjectId: String) {
    switch sdkObjectType {
    case .OpenGraph: self = .OpenGraph(objectId: sdkObjectId)
    case .Page: self = .Page(objectId: sdkObjectId)
    case .Unknown: self = .Unknown(objectId: sdkObjectId)
    }
  }

  internal var sdkObjectRepresntation: (objectType: FBSDKLikeObjectType, objectId: String) {
    switch self {
    case .OpenGraph(let objectId): return (.OpenGraph, objectId)
    case .Page(let objectId): return (.Page, objectId)
    case .Unknown(let objectId): return (.Unknown, objectId)
    }
  }
}

/**
 Compare two `LikableObject`s for equality.

 - parameter lhs: The first object to compare.
 - parameter rhs: The second object to compare.

 - returns: Whether or not the objects are equal.
 */
public func == (lhs: LikableObject, rhs: LikableObject) -> Bool {
  return lhs.sdkObjectRepresntation.objectId == rhs.sdkObjectRepresntation.objectId
}
