/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
@objc(FBSDKGamingVideoUploaderConfiguration)
public class GamingVideoUploaderConfiguration: NSObject {
  public private(set) var videoURL: URL
  public private(set) var caption: String?

  /**
   A model for Gaming video upload content to be shared.
   @param videoURL a url to the videos location on local disk.
   @param caption and optional caption that will appear along side the video on Facebook.
   */

  public init(videoURL: URL, caption: String?) {
    self.videoURL = videoURL
    self.caption = caption
  }
}
