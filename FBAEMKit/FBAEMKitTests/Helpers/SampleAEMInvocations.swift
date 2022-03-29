/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import Foundation

final class SampleAEMInvocations { // swiftlint:disable:this convenience_type
  static func createGeneralInvocation1() -> _AEMInvocation {
    _AEMInvocation(
      campaignID: "test_campaign_1",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigID: "test_config_id_123",
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
  }

  static func createGeneralInvocation2() -> _AEMInvocation {
    _AEMInvocation(
      campaignID: "test_campaign_2",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigID: "test_config_id_123",
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
  }

  static func createDebuggingInvocation() -> _AEMInvocation {
    _AEMInvocation(
      campaignID: "debugging_campaign",
      acsToken: "debugging_token",
      acsSharedSecret: "debugging_shared_secret",
      acsConfigID: "debugging_config_id_123",
      businessID: nil,
      catalogID: nil,
      isTestMode: true,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
  }

  static func createSKANOverlappedInvocation() -> _AEMInvocation {
    _AEMInvocation(
      campaignID: "debugging_campaign",
      acsToken: "debugging_token",
      acsSharedSecret: "debugging_shared_secret",
      acsConfigID: "debugging_config_id_123",
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasSKAN: true,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
  }

  static func createCatalogOptimizedInvocation() -> _AEMInvocation {
    _AEMInvocation(
      campaignID: "81", // The campaign id mod 8 (catalog optimization modulus) modulus is 1
      acsToken: "debugging_token",
      acsSharedSecret: "debugging_shared_secret",
      acsConfigID: "debugging_config_id_123",
      businessID: nil,
      catalogID: "test_catalog_id",
      isTestMode: false,
      hasSKAN: true,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
  }
}
