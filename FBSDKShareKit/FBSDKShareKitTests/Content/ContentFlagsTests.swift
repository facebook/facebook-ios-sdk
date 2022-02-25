/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import XCTest

final class ContentFlagsTests: XCTestCase {

  var flags: ContentFlags! // swiftlint:disable:this implicitly_unwrapped_optional

  func testDefaultFlags() {
    flags = ContentFlags()
    XCTAssertFalse(flags.containsMedia, .mediaFlagDefaultsToFalse)
    XCTAssertFalse(flags.containsPhotos, .photosFlagDefaultsToFalse)
    XCTAssertFalse(flags.containsVideos, .videosFlagDefaultsToFalse)
  }

  func testCustomFlags() {
    flags = allTypesFlags()
    XCTAssertTrue(flags.containsMedia, .canInitializeWithCustomFlags)
    XCTAssertTrue(flags.containsPhotos, .canInitializeWithCustomFlags)
    XCTAssertTrue(flags.containsVideos, .canInitializeWithCustomFlags)
  }

  func testContainingAllTypes() {
    flags = ContentFlags()
    XCTAssertFalse(flags.containsAllTypes, .doesNotContainAllTypes)

    flags = ContentFlags(containsMedia: true)
    XCTAssertFalse(flags.containsAllTypes, .doesNotContainAllTypes)

    flags = ContentFlags(containsPhotos: true)
    XCTAssertFalse(flags.containsAllTypes, .doesNotContainAllTypes)

    flags = ContentFlags(containsVideos: true)
    XCTAssertFalse(flags.containsAllTypes, .doesNotContainAllTypes)

    flags = allTypesFlags(containsMedia: false)
    XCTAssertFalse(flags.containsAllTypes, .doesNotContainAllTypes)

    flags = allTypesFlags(containsPhotos: false)
    XCTAssertFalse(flags.containsAllTypes, .doesNotContainAllTypes)

    flags = allTypesFlags(containsVideos: false)
    XCTAssertFalse(flags.containsAllTypes, .doesNotContainAllTypes)

    flags = allTypesFlags()
    XCTAssertTrue(flags.containsAllTypes, .containsAllTypes)
  }

  func testFlagwiseOrAssignment() {
    for _ in 1 ... 100 {
      let originalFlags = randomFlags()
      let otherFlags = randomFlags()
      let expectedFlags = ContentFlags(
        containsMedia: originalFlags.containsMedia || otherFlags.containsMedia,
        containsPhotos: originalFlags.containsPhotos || otherFlags.containsPhotos,
        containsVideos: originalFlags.containsVideos || otherFlags.containsVideos
      )
      flags = originalFlags
      flags |= otherFlags

      XCTAssertEqual(flags.containsMedia, expectedFlags.containsMedia, .flagwiseOrAssignment)
      XCTAssertEqual(flags.containsPhotos, expectedFlags.containsPhotos, .flagwiseOrAssignment)
      XCTAssertEqual(flags.containsVideos, expectedFlags.containsVideos, .flagwiseOrAssignment)
    }
  }

  // MARK: - Helpers

  private func allTypesFlags(
    containsMedia: Bool = true,
    containsPhotos: Bool = true,
    containsVideos: Bool = true
  ) -> ContentFlags {
    ContentFlags(
      containsMedia: containsMedia,
      containsPhotos: containsPhotos,
      containsVideos: containsVideos
    )
  }

  private func randomFlags() -> ContentFlags {
    ContentFlags(containsMedia: .random(), containsPhotos: .random(), containsVideos: .random())
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let mediaFlagDefaultsToFalse = "The flags should not indicate containing media by default"
  static let photosFlagDefaultsToFalse = "The flags should not indicate containing photos by default"
  static let videosFlagDefaultsToFalse = "The flags should not indicate containing videos by default"

  static let canInitializeWithCustomFlags = "Should be able to create flags with custom values"

  static let doesNotContainAllTypes = "Flags should only indicate containing all types if all values are true"
  static let containsAllTypes = "Flags should indicate containing all types if all values are true"

  static let flagwiseOrAssignment = "Should be able to combine two sets of flags using an OR assignment"
}
