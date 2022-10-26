/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// swiftlint:disable:all prefer_final_classes

import FBSDKCoreKit
import Foundation

/**
 General-purpose web dialog for presenting `fb.gg/dialog/{view}`
 - warning: INTERNAL - DO NOT USE. This class is public so that other public types may extend it.
 */
public class GamingWebDialog<Success: GamingWebDialogSuccess>: WebDialogDelegate {
  private enum Keys {
    static var path: String { "/gaming/dialog/" }
    static var errorCode: String { "error_code" }
    static var errorMessage: String { "error_message" }
  }

  public var completion: ((Result<Success, Error>) -> Void)?
  var dialog: _WebDialog?
  var parameters = [String: String]()
  var frame = CGRect.zero
  let name: String

  init(name: String) {
    self.name = name
  }

  func show(completion: @escaping (Result<Success, Error>) -> Void) {
    self.completion = completion
    dialog = _WebDialog(
      name: name,
      parameters: parameters,
      webViewFrame: frame,
      path: Keys.path + name
    )
    dialog?.delegate = self
    InternalUtility.shared.registerTransientObject(self)
    dialog?.show()
  }

  public func webDialog(_ webDialog: _WebDialog, didCompleteWithResults results: [String: Any]) {
    guard webDialog == dialog else {
      if let dialog = dialog {
        let error = _ErrorFactory().unknownError(message: "The dialog failed to retrieve results.")
        self.webDialog(dialog, didFailWithError: error)
      }
      return
    }

    if
      let errorCode = results[Keys.errorCode] as? Int,
      let errorMessage = results[Keys.errorMessage] as? String {
      let errorFactory = _ErrorFactory()
      let error = errorFactory.error(
        code: errorCode,
        userInfo: nil,
        message: errorMessage,
        underlyingError: nil
      )
      completion?(.failure(error))
      completion = nil
      return
    }

    do {
      let success = try Success(results)
      completion?(.success(success))
    } catch {
      completion?(.failure(error))
    }
    completion = nil
  }

  public func webDialog(_ webDialog: _WebDialog, didFailWithError error: Error) {
    guard webDialog == dialog else {
      return
    }
    completion?(.failure(error))
    InternalUtility.shared.unregisterTransientObject(self)
  }

  public func webDialogDidCancel(_ webDialog: _WebDialog) {
    guard webDialog == dialog else {
      return
    }
    do {
      let success = try Success([:])
      completion?(.success(success))
    } catch {
      completion?(.failure(error))
    }
    InternalUtility.shared.unregisterTransientObject(self)
  }
}
