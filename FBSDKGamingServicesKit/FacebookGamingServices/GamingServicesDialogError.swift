/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Errors to describe what went wrong with a GamingServicesDialog
 */
public enum GamingServicesDialogError: Error {
  /// Indicates an invalid content type was used with a given dialog
  case invalidContentType

  /// Indicates a failure based on missing dialog content
  case missingContent
}
