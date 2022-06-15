/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import CommonCrypto
import FBSDKCoreKit
import Foundation

/**
 Represents a code verifier used in the PKCE (Proof Key for Code Exchange)
 process. This is a cryptographically random string using the characters
 A-Z, a-z, 0-9, and the punctuation characters -._~ (hyphen, period,
 underscore, and tilde), between 43 and 128 characters long.
 */
@objcMembers
@objc(FBSDKCodeVerifier)
public final class CodeVerifier: NSObject {

  /// The string value of the code verifier
  public let value: String

  /// The SHA256 hashed challenge of the code verifier
  public var challenge: String {
    guard let data = value.data(using: .utf8) else {
      return ""
    }
    var sha256Data = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
      _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &sha256Data)
    }
    return Self.base64URLEncodeDataWithNoPadding(data: Data(sha256Data))
  }

  private static let codeVerifierByteCount = 72
  private static let codeVerifierStringLength = 43 ... 128

  /**
   Attempts to initialize a new code verifier instance with the given string.
   Creation will fail and return nil if the string is invalid.

   @param string the code verifier string
   */
  @objc(initWithString:)
  public convenience init?(string: String) {
    guard Self.codeVerifierStringLength.contains(string.count) else { return nil }

    let invalidCharacters = CharacterSet(charactersIn: "-._~")
      .union(.alphanumerics)
      .inverted

    guard string.rangeOfCharacter(from: invalidCharacters) == nil else { return nil }

    self.init(validString: string)
  }

  /**
   Initializes a new code verifier instance with a random string value
   */
  public override convenience init() {
    var randomData = [Int8](repeating: 0, count: Self.codeVerifierByteCount)

    guard SecRandomCopyBytes(kSecRandomDefault, Self.codeVerifierByteCount, &randomData) == 0 else {
      fatalError("Unable to create random data for code verifier value")
    }

    let codeVerifier = Self.base64URLEncodeDataWithNoPadding(data: Data(bytes: randomData, count: randomData.count))

    self.init(validString: codeVerifier)
  }

  private init(validString string: String) {
    value = string
    super.init()
  }

  private static func base64URLEncodeDataWithNoPadding(data: Data) -> String {
    data
      .base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

#endif
