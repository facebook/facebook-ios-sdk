/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKShareKit
import TestTools

enum ShareModelTestUtility {

  // swiftlint:disable force_unwrapping
  static let cameraEffectID = "1234567"
  static let contentURL = URL(string: "https://developers.facebook.com/")!
  static let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
  static let hashtag = Hashtag("#ashtag")
  static let isPhotoUserGenerated = true
  static let linkContentDescription = "this is my status"
  static let linkContentTitle = "my status"
  static let linkImageURL = URL(string: "https://fbcdn-dragon-a.akamaihd.net/hphotos-ak-xpa1/t39.2178-6/851594_549760571770473_1178259000_n.png")!
  static let media: [ShareMedia] = [video, photoWithImage]
  static let peopleIDs = [String]()
  static let photoImage = generatedImage
  static let photoImageURL = URL(string: "https://fbstatic-a.akamaihd.net/rsrc.php/v2/yC/r/YRwxe7CPWSs.png")!
  static let photoWithFileURL = SharePhoto(imageURL: fileURL, isUserGenerated: isPhotoUserGenerated)
  static let photoWithImage = SharePhoto(image: photoImage, isUserGenerated: isPhotoUserGenerated)
  static let photoWithImageURL = SharePhoto(imageURL: photoImageURL, isUserGenerated: isPhotoUserGenerated)
  static let placeID = "141887372509674"
  static let previewPropertyName = "myObject"
  static let quote = "quote"
  static let ref = "myref"
  static let video = ShareVideo(videoURL: videoURL)
  static let videoURL = URL(string: "assets-library://asset/asset.mp4?id=86C6970B-1266-42D0-91E8-4E68127D3864&ext=mp4")!
  static let videoWithPreviewPhoto = ShareVideo(videoURL: videoURL, previewPhoto: photoWithImageURL)
  // swiftlint:enable force_unwrapping

  static var linkContent: ShareLinkContent {
    let linkContent = linkContentWithoutQuote
    linkContent.quote = quote
    return linkContent
  }

  static var linkContentWithoutQuote: ShareLinkContent {
    let linkContent = ShareLinkContent()
    linkContent.contentURL = contentURL
    linkContent.hashtag = hashtag
    linkContent.peopleIDs = peopleIDs
    linkContent.placeID = placeID
    linkContent.ref = ref
    return linkContent
  }

  static var photoContent: SharePhotoContent {
    let content = SharePhotoContent()
    content.contentURL = contentURL
    content.hashtag = hashtag
    content.peopleIDs = peopleIDs
    content.photos = photos
    content.placeID = placeID
    content.ref = ref
    return content
  }

  static var photos: [SharePhoto] {
    [
      SharePhoto(
        imageURL: SampleURLs.validPNG,
        isUserGenerated: false
      ),
      SharePhoto(
        imageURL: SampleURLs.validPNG,
        isUserGenerated: false
      ),
      SharePhoto(
        imageURL: SampleURLs.validPNG,
        isUserGenerated: true
      ),
    ]
  }

  static var photosWithFileURLs: [SharePhoto] {
    [
      photoWithFileURL,
    ]
  }

  // equality checks are pointer equality for UIImage, so just return the same instance each time
  static var photosWithImages = [
    SharePhoto(image: generatedImage, isUserGenerated: true),
    SharePhoto(image: generatedImage, isUserGenerated: true),
    SharePhoto(image: generatedImage, isUserGenerated: true),
  ]

  static var generatedImage: UIImage = {
    UIGraphicsBeginImageContext(CGSize(width: 10.0, height: 10.0))
    guard let context = UIGraphicsGetCurrentContext() else {
      fatalError("Must be able to get a current context")
    }
    UIColor.red.setFill()
    context.fill(CGRect(x: 0.0, y: 0.0, width: 5.0, height: 5.0))
    UIColor.green.setFill()
    context.fill(CGRect(x: 5.0, y: 0.0, width: 5.0, height: 5.0))
    UIColor.blue.setFill()
    context.fill(CGRect(x: 5.0, y: 5.0, width: 5.0, height: 5.0))
    UIColor.yellow.setFill()
    context.fill(CGRect(x: 0.0, y: 5.0, width: 5.0, height: 5.0))
    guard let imageRef = context.makeImage() else {
      fatalError("Must be able to make a cg image")
    }
    UIGraphicsEndImageContext()
    return UIImage(cgImage: imageRef)
  }()

  static var photoContentWithFileURLs: SharePhotoContent {
    let content = SharePhotoContent()
    content.contentURL = contentURL
    content.hashtag = hashtag
    content.peopleIDs = peopleIDs
    content.photos = photosWithFileURLs
    content.placeID = placeID
    content.ref = ref
    return content
  }

  static var photoContentWithImages: SharePhotoContent {
    let content = SharePhotoContent()
    content.contentURL = contentURL
    content.hashtag = hashtag
    content.peopleIDs = peopleIDs
    content.photos = photosWithImages
    content.placeID = placeID
    content.ref = ref
    return content
  }

  static var videoContentWithoutPreviewPhoto: ShareVideoContent {
    let content = ShareVideoContent()
    content.contentURL = contentURL
    content.hashtag = hashtag
    content.peopleIDs = peopleIDs
    content.placeID = placeID
    content.ref = ref
    content.video = video
    return content
  }

  static var videoContentWithPreviewPhoto: ShareVideoContent {
    let content = ShareVideoContent()
    content.contentURL = contentURL
    content.hashtag = hashtag
    content.peopleIDs = peopleIDs
    content.placeID = placeID
    content.ref = ref
    content.video = videoWithPreviewPhoto
    return content
  }

  static var mediaContent: ShareMediaContent {
    let content = ShareMediaContent()
    content.media = media
    return content
  }

  static var multiVideoMediaContent: ShareMediaContent {
    let content = ShareMediaContent()
    content.media = [video, video]
    return content
  }

  static var cameraEffectArguments: CameraEffectArguments {
    let arguments = CameraEffectArguments()
    arguments.set("A string argument", forKey: "stringArg1")
    arguments.set("Another string argument", forKey: "stringArg2")
    return arguments
  }

  static var cameraEffectContent: ShareCameraEffectContent {
    let content = ShareCameraEffectContent()
    content.effectID = cameraEffectID
    content.effectArguments = cameraEffectArguments
    return content
  }
}
