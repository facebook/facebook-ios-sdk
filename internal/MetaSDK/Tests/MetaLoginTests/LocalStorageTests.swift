// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import XCTest
@testable import MetaLogin

class LocalStorageTests: XCTestCase {
    var localStorage: LocalStorage!
    var dataStorage: TestDataStorage!

    override func setUp() {
        super.setUp()
        
        localStorage = LocalStorage()
        dataStorage = TestDataStorage()
        localStorage.setDependencies(
            .init(dataStorage: dataStorage)
        )
    }

    override func tearDown() {
        localStorage = nil
        dataStorage = nil
        
        super.tearDown()
    }

    func testDefaultDependencies() throws {
        localStorage.resetDependencies()
        let dependencies = try localStorage.getDependencies()

        XCTAssertEqual(
            dependencies.dataStorage as? UserDefaults,
            UserDefaults.standard,
            "Local storage uses the shared user defaults object"
        )
    }

    func testCustomDependencies() throws {
        let dependencies = try localStorage.getDependencies()

        XCTAssertIdentical(
          dependencies.dataStorage as AnyObject,
          dataStorage,
          "Should be set to custom data storage."
        )
    }
    
    func testSettingAuthenticationSessionState() throws {
        localStorage.authenticationSessionState = .performingLogin
        XCTAssertEqual(dataStorage.capturedSetIntegerForKeyName, LocalStorage.persistenceKey, "The persistence key should be passed to data storage")
        XCTAssertEqual(dataStorage.capturedSetValue, AuthenticationSessionState.performingLogin.rawValue, "The session state should be set to the assigned value")
    }
    
    func testGettingAuthenticationSessionState() throws {
        let sessionState = localStorage.authenticationSessionState
        XCTAssertEqual(dataStorage.capturedIntegerForKeyName, LocalStorage.persistenceKey)
        XCTAssertEqual(sessionState, .none, "Session state should be none when no session state is stored")
    }
    
    func testGettingAuthenticationSessionStateWithStoredValue() throws {
        dataStorage.stubbedIntegerForKey = 1
        let sessionState = localStorage.authenticationSessionState
        XCTAssertEqual(sessionState, .performingLogin, "Session state should be active when there exists a session to retrieve")
    }
    
    func testGettingAuthenticationSessionStateWithInvalidValue() throws {
        dataStorage.stubbedIntegerForKey = 3
        let sessionState = localStorage.authenticationSessionState
        XCTAssertEqual(sessionState, .none, "Session state should be none for a value that doesn't match a session state")
    }
}
