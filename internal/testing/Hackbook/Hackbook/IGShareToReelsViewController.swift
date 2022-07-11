// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit
import Photos
import MobileCoreServices

class IGShareToReelsViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  // This is the url scheme that third party app will call
  private let urlScheme = "instagram-reels://share"

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Share to Reels"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ShareToReelsCell")
    tableView.rowHeight = 44
  }

  // MARK: Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    0 == section ? 3 : 1
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    0 == section ? "Editor" : "Error"
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 0:
      switch indexPath.row {
      case 0: shareDemoVideo()
      case 1: selectVideoFromAssetLibrary()
      case 2: shareDemoVideoWithSticker()
      default: break
      }
    case 1:
      switch indexPath.row {
      case 0: shareWithoutVideo()
      default: break
      }
    default: break
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ShareToReelsCell", for: indexPath)
    cell.selectionStyle = .none
    cell.accessoryType = .disclosureIndicator

    let options = [["Video", "Video from Asset Library", "Video with Sticker"], ["Missing the Media"]]
    cell.textLabel?.text = options[indexPath.section][indexPath.row]

    return cell
  }

  // MARK: - UIImagePickerControllerDelegate
  public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true, completion: nil)
    if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL,
      let videoData = try? Data(contentsOf: videoUrl) {
        share(video: videoData)
    }
  }

  private func share(video: Data) {
    if shareToReels(backgroundVideo:video, stickerImage:nil) {
      ConsoleSucceedWithFormattedMessage("openURL:\(urlScheme)")
    } else {
      ConsoleReportBugWithFormattedMessage("canOpenURL:\(urlScheme) returned false")
    }
  }

  private func shareDemoVideo() {
    guard let videoUrl = Bundle.main.url(forResource: "videoviewdemo", withExtension: "mp4"),
      let videoData = try? Data.init(contentsOf: videoUrl) as Data
    else {
      ConsoleReportBugWithFormattedMessage("process demo video failed")
      return
    }
    share(video: videoData)
  }

  private func selectVideoFromAssetLibrary() {
    PHPhotoLibrary.requestAuthorization { status in
      switch status {
      case .authorized:
        DispatchQueue.main.async {
          let imagePicker = UIImagePickerController()
          imagePicker.mediaTypes = [
            kUTTypeMovie as String,
            kUTTypeAVIMovie as String,
            kUTTypeVideo as String,
            kUTTypeMPEG4 as String
          ]
          imagePicker.sourceType = .photoLibrary
          imagePicker.videoQuality = .typeHigh
          imagePicker.allowsEditing = false
          imagePicker.delegate = self
          imagePicker.modalPresentationStyle = .popover
          self.present(imagePicker, animated: true, completion: nil)
        }
      default: break
      }
    }
  }

  private func shareDemoVideoWithSticker() {
    guard let videoUrl = Bundle.main.url(forResource: "videoviewdemo", withExtension: "mp4"),
          let videoData = try? Data.init(contentsOf: videoUrl) as Data
    else {
      ConsoleReportBugWithFormattedMessage("process demo video failed")
      return
    }
    let stickerImageURL = "https://i.scdn.co/image/920142fb308970e28aade4a288041a4d1b8f9519"
    let stickerImage = imageFromURL(imageURL:stickerImageURL)

    let stickerImageData = stickerImage?.pngData()
    if shareToReels(backgroundVideo:videoData, stickerImage:stickerImageData) {
      ConsoleSucceedWithFormattedMessage("openURL:\(urlScheme)")
    } else {
      ConsoleReportBugWithFormattedMessage("canOpenURL:\(urlScheme) returned false")
    }
  }
  
  private func shareWithoutVideo() {
    if shareToReels(backgroundVideo:nil, stickerImage:nil) {
      ConsoleSucceedWithFormattedMessage("openURL:\(urlScheme)")
    } else {
      ConsoleReportBugWithFormattedMessage("canOpenURL:\(urlScheme) returned false")
    }
  }

  private func imageFromURL(imageURL:String) -> UIImage? {
    guard let url = URL(string: imageURL),
          let image = try? UIImage(data: Data(contentsOf: url))
    else{
      ConsoleReportBugWithFormattedMessage("Failed to create image from url: \(imageURL)")
    return nil
    }
    
    return image
  }
}
