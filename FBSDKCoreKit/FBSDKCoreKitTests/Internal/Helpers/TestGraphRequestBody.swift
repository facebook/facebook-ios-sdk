/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestGraphRequestBody: GraphRequestBody {
  var capturedKey: String?
  var capturedFormValue: String?
  var capturedImage: UIImage?
  var capturedData: Data?
  var capturedAttachment: GraphRequestDataAttachment?

  override func append(withKey key: String, formValue value: String, logger: Logger?) {
    capturedKey = key
    capturedFormValue = value
  }

  override func append(withKey key: String, imageValue image: UIImage, logger: Logger?) {
    capturedImage = image
  }

  override func append(withKey key: String, dataValue data: Data, logger: Logger?) {
    capturedData = data
  }

  override func append(
    withKey key: String,
    dataAttachmentValue dataAttachment: GraphRequestDataAttachment,
    logger: Logger?
  ) {
    capturedAttachment = dataAttachment
  }
}
