// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import MobileCoreServices
import Photos
import UIKit

class ShareToReelsViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  // This is the url scheme that third party app will call
  private let urlScheme = "facebook-reels://share"

  private enum ShareSettings {
    static let spotifyAppID = "174829003346"
    static let spotifyContentURL = "https://open.spotify.com/track/7iN1s7xHE4ifF5povM6A48?si=FbT3st_AbEoITqaTBG6Js-&utm_source=facebook"
    static let demoAppID = "1048133622404663"
    static let demoContentURL = "https://mycompany.com/abc"
    static let nonExistentAppID = "1111111111111111"
    static let devModeAppID = "606023801621533"
    static let enforcedAppID = "1695980867507755"
  }

  let options = [["Video", "Video from Asset Library", "Video from Spotify", "Video from Test Party", "Video with Sticker"], ["Missing App ID", "Invalid App ID", "Non-existent App ID", "App on Dev Mode", "Enforced App", "Missing the Media"]]

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Share to Reels"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ShareToReelsCell")
    tableView.rowHeight = 44
  }

  // MARK: Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    options.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    options[section].count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    section == 0 ? "Editor" : "Error"
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 0:
      switch indexPath.row {
      case 0: shareDemoVideo()
      case 1: selectVideoFromAssetLibrary()
      case 2: shareDemoVideoFromSpotify()
      case 3: shareVideoFromTestParty()
      case 4: shareDemoVideoWithSticker()
      default: break
      }
    case 1:
      switch indexPath.row {
      case 0: shareWithoutAppID()
      case 1: shareWithInvalidAppID()
      case 2: shareWithNonExistentAppID()
      case 3: shareWithDevModeAppID()
      case 4: shareWithEnforcedAppID()
      case 5: shareWithoutVideo()
      default: break
      }
    default: break
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ShareToReelsCell", for: indexPath)
    cell.selectionStyle = .none
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.text = options[indexPath.section][indexPath.row]

    return cell
  }

  // MARK: - UIImagePickerControllerDelegate

  public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true, completion: nil)
    if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL,
       let videoData = try? Data(contentsOf: videoUrl) as Data {
      share(video: videoData)
    }
  }

  private func share(video: Data) {
    if FBSDKPlatformSharingToReels(Settings.shared.appID, video, nil, nil) {
      ConsoleSucceedWithFormattedMessage("openURL:\(urlScheme)")
    } else {
      ConsoleReportBugWithFormattedMessage("canOpenURL:\(urlScheme) returned false")
    }
  }

  private func shareFrom(appID: String?, contentURL: String? = nil, stickerImageURL: String? = nil) {
    guard let videoUrl = Bundle.main.url(forResource: "videoviewdemo", withExtension: "mp4"),
          let videoData = try? Data(contentsOf: videoUrl) as Data
    else {
      ConsoleReportBugWithFormattedMessage("process demo video failed")
      return
    }

    let stickerImageData = stickerImageURL != nil ? imageFromURL(imageURL: stickerImageURL! as String)?.pngData() : nil

    if FBSDKPlatformSharingToReels(appID, videoData, contentURL, stickerImageData) {
      ConsoleSucceedWithFormattedMessage("openURL:\(urlScheme)")
    } else {
      ConsoleReportBugWithFormattedMessage("canOpenURL:\(urlScheme) returned false")
    }
  }

  private func shareDemoVideo() {
    guard let videoUrl = Bundle.main.url(forResource: "videoviewdemo", withExtension: "mp4"),
          let videoData = try? Data(contentsOf: videoUrl) as Data
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
          imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeAVIMovie as String, kUTTypeVideo as String, kUTTypeMPEG4 as String]
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

  private func shareDemoVideoFromSpotify() {
    shareFrom(appID: ShareSettings.spotifyAppID, contentURL: ShareSettings.spotifyContentURL)
  }

  private func shareDemoVideoWithSticker() {
    shareFrom(appID: ShareSettings.spotifyAppID, stickerImageURL: "https://i.scdn.co/image/920142fb308970e28aade4a288041a4d1b8f9519")
  }

  private func shareVideoFromTestParty() {
    shareFrom(appID: ShareSettings.demoAppID, contentURL: ShareSettings.demoContentURL)
  }

  private func shareWithoutAppID() {
    shareFrom(appID: nil)
  }

  private func shareWithInvalidAppID() {
    shareFrom(appID: "invalid_app_id")
  }

  private func shareWithNonExistentAppID() {
    shareFrom(appID: ShareSettings.nonExistentAppID)
  }

  private func shareWithDevModeAppID() {
    shareFrom(appID: ShareSettings.devModeAppID)
  }

  private func shareWithEnforcedAppID() {
    shareFrom(appID: ShareSettings.enforcedAppID)
  }

  private func shareWithoutVideo() {
    if FBSDKPlatformSharingToReels(Settings.shared.appID, nil, nil, nil) {
      ConsoleSucceedWithFormattedMessage("openURL:\(urlScheme)")
    } else {
      ConsoleReportBugWithFormattedMessage("canOpenURL:\(urlScheme) returned false")
    }
  }

  private func imageFromURL(imageURL: String) -> UIImage? {

    guard let url = URL(string: imageURL) else { return nil }
    return try! UIImage(data: Data(contentsOf: url))
  }
}
