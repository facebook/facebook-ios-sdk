/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
@objc(FBSDKGamingImageUploader)
public final class GamingImageUploader: NSObject {

  private var progressHandler: GamingServiceProgressHandler?

  let factory: GamingServiceControllerCreating
  let graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol

  // Transitional singleton introduced as a way to change the usage semantics
  // from a type-based interface to an instance-based interface.
  static let shared = GamingImageUploader()

  override convenience init() {
    self.init(
      gamingServiceControllerFactory: GamingServiceControllerFactory(),
      graphRequestConnectionFactory: GraphRequestConnectionFactory()
    )
  }

  convenience init(progressHandler: GamingServiceProgressHandler?) {
    self.init(
      gamingServiceControllerFactory: GamingServiceControllerFactory(),
      graphRequestConnectionFactory: GraphRequestConnectionFactory()
    )
    self.progressHandler = progressHandler
  }

  init(
    gamingServiceControllerFactory: GamingServiceControllerCreating,
    graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol
  ) {
    factory = gamingServiceControllerFactory
    self.graphRequestConnectionFactory = graphRequestConnectionFactory
  }

  /**
   Runs an upload to a users Gaming Media Library with the given configuration

   @param configuration model object contain the content that will be uploaded
   @param completion a callback that is fired dependent on the configuration.
   Fired when the upload completes or when the users returns to the caller app
   after the media dialog is shown.
   */
  @objc(uploadImageWithConfiguration:andResultCompletion:)
  public static func uploadImage(
    with configuration: GamingImageUploaderConfiguration,
    andResultCompletion completion: @escaping GamingServiceResultCompletion
  ) {
    shared.uploadImage(
      with: configuration,
      andResultCompletion: completion
    )
  }

  func uploadImage(
    with configuration: GamingImageUploaderConfiguration,
    andResultCompletion completion: @escaping GamingServiceResultCompletion
  ) {
    uploadImage(
      with: configuration,
      completion: completion,
      andProgressHandler: nil
    )
  }

  /**
   Runs an upload to a users Gaming Media Library with the given configuration

   @param configuration model object contain the content that will be uploaded
   @param completion a callback that is fired dependent on the configuration.
   Fired when the upload completes or when the users returns to the caller app
   after the media dialog is shown.
   @param progressHandler an optional callback that is fired multiple times as
   bytes are transferred to Facebook.
   */
  @objc(uploadImageWithConfiguration:completion:andProgressHandler:)
  public static func uploadImage(
    with configuration: GamingImageUploaderConfiguration,
    completion: @escaping GamingServiceResultCompletion,
    andProgressHandler progressHandler: GamingServiceProgressHandler?
  ) {
    shared.uploadImage(
      with: configuration,
      completion: completion,
      andProgressHandler: progressHandler
    )
  }

  func uploadImage(
    with configuration: GamingImageUploaderConfiguration,
    completion completionHandler: @escaping GamingServiceResultCompletion,
    andProgressHandler progressHandler: GamingServiceProgressHandler?
  ) {
    let errorFactory = ErrorFactory()

    if AccessToken.current == nil {
      completionHandler(
        false,
        nil,
        errorFactory.error(
          code: CoreError.errorAccessTokenRequired.rawValue,
          userInfo: nil,
          message: "A valid access token is required to upload Images",
          underlyingError: nil
        )
      )

      return
    }

    guard let imageData = configuration.image.pngData() else {
      completionHandler(
        false,
        nil,
        errorFactory.error(
          code: CoreError.errorInvalidArgument.rawValue,
          userInfo: nil,
          message: "Attempting to upload a nil image",
          underlyingError: nil
        )
      )

      return
    }

    let connection = graphRequestConnectionFactory.createGraphRequestConnection()

    let uploader = GamingImageUploader(progressHandler: progressHandler)

    connection.delegate = uploader
    InternalUtility.shared.registerTransientObject(connection.delegate as Any)

    connection.add(
      GraphRequest(
        graphPath: "me/photos",
        parameters: [
          "caption": configuration.caption ?? "",
          "picture": imageData,
        ],
        httpMethod: .post
      )
    ) { [weak self] graphConnection, result, error in
      guard let strongSelf = self else { return }

      if let graphConnectionDelegate = graphConnection?.delegate {
        InternalUtility.shared.unregisterTransientObject(graphConnectionDelegate)
      }

      if error != nil || result == nil {
        completionHandler(
          false,
          nil,
          errorFactory.error(
            code: CoreError.errorGraphRequestGraphAPI.rawValue,
            userInfo: nil,
            message: "Image upload failed",
            underlyingError: error
          )
        )
        return
      }

      let result = result as? [String: Any]

      if !configuration.shouldLaunchMediaDialog {
        completionHandler(true, result, nil)
        return
      }

      let controller = strongSelf.factory.create(
        serviceType: .mediaAsset,
        pendingResult: result,
        completion: completionHandler
      )

      controller.call(withArgument: result?["id"] as? String)
    }

    connection.start()
  }
}

// MARK: - GraphRequestConnectionDelegate

extension GamingImageUploader: GraphRequestConnectionDelegate {

  public func requestConnection(
    _ connection: GraphRequestConnecting,
    didSendBodyData bytesWritten: Int,
    totalBytesWritten: Int,
    totalBytesExpectedToWrite: Int
  ) {
    guard let progressHandler = progressHandler else { return }

    progressHandler(
      Int64(bytesWritten),
      Int64(totalBytesWritten),
      Int64(totalBytesExpectedToWrite)
    )
  }
}
