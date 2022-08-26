/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Internal typealias exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
public typealias LoginTooltipBlock = (FBSDKLoginTooltip?, Error?) -> Void

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
public enum LoginTooltipError: Error {
  case missingTooltipText
}

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
public final class ServerConfigurationProvider: NSObject {

  public var loggingToken: String? {
    _ServerConfigurationManager.shared.cachedServerConfiguration().loggingToken
  }

  public func shouldUseSafariViewController(forDialogName dialogName: String) -> Bool {
    _ServerConfigurationManager.shared.cachedServerConfiguration().useSafariViewController(forDialogName: dialogName)
  }

  public func loadServerConfiguration(completion: LoginTooltipBlock?) {
    _ServerConfigurationManager.shared.loadServerConfiguration { potentialConfiguration, potentialError in
      DispatchQueue.main.async {
        guard let tooltipCompletion = completion else { return }

        guard let configuration = potentialConfiguration,
              potentialError == nil
        else {
          return tooltipCompletion(nil, potentialError)
        }

        guard let text = configuration.loginTooltipText else {
          return tooltipCompletion(nil, LoginTooltipError.missingTooltipText)
        }

        let tooltip = FBSDKLoginTooltip(
          text: text,
          enabled: configuration.isLoginTooltipEnabled
        )

        tooltipCompletion(tooltip, nil)
      }
    }
  }
}
