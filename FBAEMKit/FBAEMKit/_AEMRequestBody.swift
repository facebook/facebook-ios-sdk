/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMRequestBody)
public final class _AEMRequestBody: NSObject {

  /// Compressed version of `data`
  public func compressedData() -> Data? {
    if data.isEmpty {
      return nil
    }
    return BasicUtility.gzip(data)
  }

  #if DEBUG
  public var multipartData: Data {
    _data
  }
  #endif

  /// Requests Constants
  private enum Constants {
    static let kNewline = "\r\n"
  }

  /// Callback alias
  typealias AEMCodeBlock = () -> Void

  public var data: Data {
    var jsonData = Data()
    if !json.keys.isEmpty,
       let data = try? TypeUtility.data(withJSONObject: json, options: .sortedKeys) {
      jsonData = data
    }
    return jsonData
  }

  private var _data = Data()

  /// JSON Dictionary
  private var json = [String: Any]()

  @objc(appendWithKey:formValue:)
  public func append(withKey key: String?, formValue value: String?) {
    _append(with: key, filename: nil, contentType: nil) { [weak self] in
      guard let value = value else {
        return
      }
      self?.append(utf8: value)
    }

    if let key = key,
       let value = value {
      json[key] = value
    }
  }

  private func append(utf8: String) {
    if _data.isEmpty {
      let headerUTF8 = String(format: "--%@", Constants.kNewline)
      let headerData = headerUTF8.data(using: .utf8) ?? Data()
      _data.append(headerData)
    }
    guard let data = utf8.data(using: .utf8) else {
      return
    }
    _data.append(data)
  }

  private func _append(
    with key: String?,
    filename: String?,
    contentType: String?,
    contentBlock: AEMCodeBlock?
  ) {
    var disposition = [String]()
    disposition.append("Content-Disposition: form-data")
    if let key = key {
      disposition.append("name=\"\(key)\"")
    }

    if let filename = filename {
      disposition.append("filename=\"\(filename)\"")
    }
    append(utf8: "\(disposition.joined(separator: "; "))\(Constants.kNewline)")
    if let contentType = contentType {
      append(utf8: "Content-Type: \(contentType)\(Constants.kNewline)")
    }
    append(utf8: Constants.kNewline)
    contentBlock?()
    append(utf8: Constants.kNewline)
  }
}

#endif
