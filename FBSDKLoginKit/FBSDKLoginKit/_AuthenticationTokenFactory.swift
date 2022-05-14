/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import CommonCrypto
import FBSDKCoreKit_Basics
import Security

/**
 Class responsible for generating an `AuthenticationToken` given a valid token string.
 An `AuthenticationToken` is verified based of the OpenID Connect Protocol.
 */
@objc(FBSDKAuthenticationTokenFactory)
public final class _AuthenticationTokenFactory: NSObject, _AuthenticationTokenCreating {
  typealias PublicCertCompletionHandler = (SecCertificate?) -> Void
  typealias PublicKeyCompletionHandler = (SecKey?) -> Void
  typealias VerifySignatureCompletionHandler = (Bool) -> Void

  let beginCertificate = "-----BEGIN CERTIFICATE-----"
  let endCertificate = "-----END CERTIFICATE-----"
  var sessionProvider: SessionProviding = URLSession(configuration: .default)
  var certificateEndpoint: URL {
    var error: NSError?
    return Utility.unversionedFacebookURL(
      withHostPrefix: "m",
      path: "/.well-known/oauth/openid/certs/",
      queryParameters: [:],
      error: &error
    )
  }

  // MARK: - Init

  convenience init(sessionProvider: SessionProviding) {
    self.init()
    self.sessionProvider = sessionProvider
  }

  // MARK: - Verification

  /**
   Create an `AuthenticationToken` given a valid token string.
   Returns nil to the completion handler if the token string is invalid
   An `AuthenticationToken` is verified based of the OpenID Connect Protocol.
   @param tokenString the raw ID token string
   @param nonce the nonce string used to associate a client session with the token
   @param graphDomain the graph domain where user is authenticated
   @param completion the completion handler
   */
  public func createToken(
    tokenString: String,
    nonce: String,
    graphDomain: String,
    completion: @escaping AuthenticationTokenBlock
  ) {
    guard
      !tokenString.isEmpty,
      !nonce.isEmpty
    else {
      completion(nil)
      return
    }

    let segments = tokenString.components(separatedBy: ".")

    guard
      segments.count == 3
    else {
      completion(nil)
      return
    }

    let encodedHeader = segments[0]
    let encodedClaims = segments[1]
    let signature = segments[2]

    let claims = AuthenticationTokenClaims(fromEncodedString: encodedClaims, nonce: nonce)
    let header = _AuthenticationTokenHeader(fromEncodedString: encodedHeader)

    guard
      claims != nil,
      let header = header
    else {
      completion(nil)
      return
    }

    verifySignature(signature, header: encodedHeader, claims: encodedClaims, certificateKey: header.kid) { success in
      if success {
        let token = AuthenticationToken(tokenString: tokenString, nonce: nonce, graphDomain: graphDomain)
        completion(token)
      } else {
        completion(nil)
      }
    }
  }

  func verifySignature(
    _ signature: String,
    header: String,
    claims: String,
    certificateKey: String,
    completion: @escaping VerifySignatureCompletionHandler
  ) {
    let signatureData = Base64.decode(asData: Base64.base64(fromBase64Url: signature))
    let signedString = "\(header).\(claims)"
    let signedData = signedString.data(using: .ascii)

    getPublicKeyWith(certificateKey: certificateKey) { key in
      fb_dispatch_on_main_thread {
        guard
          let key = key,
          let signatureData = signatureData,
          let signedData = signedData
        else {
          completion(false)
          return
        }

        let signatureBytesSize = SecKeyGetBlockSize(key)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        signedData.withUnsafeBytes { signedBytes in
          _ = CC_SHA256(signedBytes.baseAddress, UInt32(signedData.count), &digest)
        }

        let mutableSignatureData = NSMutableData(data: signatureData)

        let status = SecKeyRawVerify(
          key,
          SecPadding.PKCS1SHA256,
          digest,
          digest.count,
          mutableSignatureData.mutableBytes.assumingMemoryBound(to: UInt8.self),
          signatureBytesSize
        )

        completion(status == errSecSuccess)
      }
    }
  }

  func getPublicKeyWith(certificateKey: String, completion: @escaping PublicKeyCompletionHandler) {
    getCertificateWith(certificateKey: certificateKey) { cert in
      var publicKey: SecKey?

      guard let cert = cert else {
        completion(publicKey)
        return
      }

      let policy = SecPolicyCreateBasicX509()
      var trust: SecTrust?

      let status = SecTrustCreateWithCertificates(cert, policy, &trust)

      if status == errSecSuccess, let trust = trust {
        publicKey = SecTrustCopyPublicKey(trust)
      }

      completion(publicKey)
    }
  }

  func getCertificateWith(certificateKey: String, completion: @escaping PublicCertCompletionHandler) {
    let request = URLRequest(url: certificateEndpoint)
    sessionProvider.dataTask(with: request) { data, response, error in
      guard
        error == nil,
        let data = data,
        let response = response,
        (response as? HTTPURLResponse)?.statusCode == 200
      else {
        completion(nil)
        return
      }

      do {
        guard
          let certs = try JSONSerialization.jsonObject(with: data) as? [String: String],
          var certString = certs[certificateKey]
        else {
          completion(nil)
          return
        }

        certString = certString.replacingOccurrences(of: self.beginCertificate, with: "")
        certString = certString.replacingOccurrences(of: self.endCertificate, with: "")
        certString = certString.replacingOccurrences(of: "\n", with: "")

        guard
          let secCertificateData = Data(base64Encoded: certString)
        else {
          completion(nil)
          return
        }
        completion(SecCertificateCreateWithData(kCFAllocatorDefault, secCertificateData as CFData))
      } catch {
        completion(nil)
      }
    }
    .resume()
  }
}

#endif
