/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

/**
 * A container of arguments for a camera effect.
 * An argument is a `String` or `[String]` identified by a `String` key.
 */
@objcMembers
@objc(FBSDKCameraEffectArguments)
public final class CameraEffectArguments: NSObject {

  private(set) var arguments = [String: Any]()

  /**
   Sets a string argument in the container.
   @param string The argument
   @param key The key for the argument
   */
  @objc(setString:forKey:)
  public func set(_ string: String?, forKey key: String) {
    arguments[key] = string
  }

  /**
   Gets a string argument from the container.
   @param key The key for the argument
   @return The string value or nil
   */
  public func string(forKey key: String) -> String? {
    arguments[key] as? String
  }

  /**
   Sets a string array argument in the container.
   @param array The array argument
   @param key The key for the argument
   */
  @objc(setArray:forKey:)
  public func set(_ array: [String]?, forKey key: String) {
    arguments[key] = array
  }

  /**
   Gets an array argument from the container.
   @param key The key for the argument
   @return The array argument
   */
  public func array(forKey key: String) -> [String]? {
    arguments[key] as? [String]
  }
}

#endif
