/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKShareKit
import XCTest

final class CameraEffectTexturesTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var textures: CameraEffectTextures!
  let key = "sample-key"
  var image: UIImage!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    image = UIImage()
    textures = CameraEffectTextures()
  }

  override func tearDown() {
    image = nil
    textures = nil

    super.tearDown()
  }

  func testAddingImage() {
    textures.set(image, forKey: key)
    XCTAssertIdentical(textures.image(forKey: key), image, .canAddImage)
  }

  func testReplacingImage() {
    textures.set(image, forKey: key)
    let newImage = UIImage()
    textures.set(newImage, forKey: key)

    XCTAssertIdentical(textures.image(forKey: key), newImage, .canReplaceImage)
  }

  func testClearingImage() {
    textures.set(image, forKey: key)
    textures.set(nil, forKey: key)
    XCTAssertNil(textures.image(forKey: key), .canClearImage)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let canAddImage = "Can add an image by key in a camera effect textures"
  static let canReplaceImage = "Can replace an image for a key in a camera effect textures"
  static let canClearImage = "Can remove an image for a key in a camera effect textures"
}
