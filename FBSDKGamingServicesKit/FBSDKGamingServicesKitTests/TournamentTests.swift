/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import XCTest

final class TournamentTests: XCTestCase {

  enum Keys {
    static let tournamentID = "id"
    static let tournamentEndTime = "tournament_end_time"
    static let tournamentTitle = "tournament_title"
    static let tournamentPayload = "tournament_payload"
  }

  enum Values {
    static let tournamentID = "4227416214015447"
    static let tournamentEndTime = "2021-09-24T18:03:47+0000"
    static let tournamentTitle = "test title"
    static let tournamentPayload = "test payload"
  }

  func testCreatingWithMissingID() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data that is missing an ID")
    } catch {
      XCTAssert(
        error is DecodingError,
        "Should not decode a tournament from data that is missing an ID"
      )
    }
  }

  func testCreatingWithInvalidID() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: 123,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid ID")
    } catch {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithMissingEndTime() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data that is missing the ent time")
    } catch {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithInvalidEndTime() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: 123,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid end time")
    } catch {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithMissingTitle() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentPayload: Values.tournamentPayload,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      let tournament = try JSONDecoder().decode(Tournament.self, from: data)
      XCTAssertNotNil(tournament, "Should be able to create a tournament with a missing title")
    } catch {
      XCTFail("Unexpected error received: \(error)")
    }
  }

  func testCreatingWithInvalidTitle() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: 123,
      Keys.tournamentPayload: Values.tournamentPayload,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid title")
    } catch {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithMissingPayload() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      let tournament = try JSONDecoder().decode(Tournament.self, from: data)
      XCTAssertNotNil(tournament, "Should be able to create a tournament with a missing payload")
    } catch {
      XCTFail("Unexpected error received: \(error)")
    }
  }

  func testCreatingWithInvalidPayload() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: 123,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid payload")
    } catch {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithValidInfo() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload,
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      let tournament = try JSONDecoder().decode(Tournament.self, from: data)
      XCTAssertNotNil(tournament)
    } catch {
      XCTFail("Unexpected error received: \(error)")
    }
  }
}
