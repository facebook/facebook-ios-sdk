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

// swiftlint:disable untyped_error_in_catch

@testable import FacebookGamingServices
import XCTest

class TournamentTests: XCTestCase {

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
      Keys.tournamentPayload: Values.tournamentPayload
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data that is missing an ID")
    } catch let error {
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
      Keys.tournamentPayload: Values.tournamentPayload
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid ID")
    } catch let error {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithMissingEndTime() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data that is missing the ent time")
    } catch let error {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithInvalidEndTime() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: 123,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid end time")
    } catch let error {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithMissingTitle() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentPayload: Values.tournamentPayload
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      let tournament = try JSONDecoder().decode(Tournament.self, from: data)
      XCTAssertNotNil(tournament, "Should be able to create a tournament with a missing title")
    } catch let error {
      XCTFail("Unexpected error received: \(error)")
    }
  }

  func testCreatingWithInvalidTitle() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: 123,
      Keys.tournamentPayload: Values.tournamentPayload
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid title")
    } catch let error {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithMissingPayload() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      let tournament = try JSONDecoder().decode(Tournament.self, from: data)
      XCTAssertNotNil(tournament, "Should be able to create a tournament with a missing payload")
    } catch let error {
      XCTFail("Unexpected error received: \(error)")
    }
  }

  func testCreatingWithInvalidPayload() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: 123
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      _ = try JSONDecoder().decode(Tournament.self, from: data)
      XCTFail("Should not create a tournament from data with an invalid payload")
    } catch let error {
      XCTAssert(error is DecodingError)
    }
  }

  func testCreatingWithValidInfo() throws {
    let tournamentInfo: [String: Any] = [
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentPayload: Values.tournamentPayload
    ]
    let data = try JSONSerialization.data(withJSONObject: tournamentInfo, options: [])
    do {
      let tournament = try JSONDecoder().decode(Tournament.self, from: data)
      XCTAssertNotNil(tournament)
    } catch let error {
      XCTFail("Unexpected error received: \(error)")
    }
  }
}
