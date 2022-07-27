/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */
import Foundation

protocol UserSessionPersisting {
    func saveUserSession(userSession: UserSession) throws
    func deleteUserSession() throws
    func getUserSession() throws -> UserSession
}
