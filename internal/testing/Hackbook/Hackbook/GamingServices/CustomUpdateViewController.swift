// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKGamingServicesKit
import Photos
import UIKit

@objcMembers
public class CustomUpdateViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet var contextTokenIDField: UITextField!
  @IBOutlet weak var customTextField: UITextField!
  @IBOutlet weak var CTAField: UITextField!
  @IBOutlet var gifURLField: UITextField!
  @IBOutlet var imageView: UIImageView!

  var imagePicker = UIImagePickerController()

  public override func viewDidLoad() {
    if GamingContext.current?.identifier != nil {
      contextTokenIDField.text = GamingContext.current?.identifier
    } else {
      contextTokenIDField.placeholder = "Manually enter a context ID or use context dialogs"
    }
    customTextField.placeholder = "Add text for custom update message"
    CTAField.placeholder = "Join Game"
    gifURLField.text = "https://media.giphy.com/media/7ISIRaCMrgFfa/giphy.gif"

    contextTokenIDField.delegate = self
    customTextField.delegate = self
    CTAField.delegate = self
    gifURLField.delegate = self
    imagePicker.delegate = self
  }

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
  }

  @IBAction func uploadImage() {
    var photoAccess = PHPhotoLibrary.authorizationStatus()
    if photoAccess == .notDetermined {
      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          photoAccess = status
        } else {}
      }
    }

    if photoAccess == .authorized {
      if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {

        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false

        present(imagePicker, animated: true, completion: nil)
      } else {

      }
    }
  }

  func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
    self.dismiss(animated: true)

    imageView.image = image
  }

  @IBAction func sendCustomUpdate(_ sender: Any) {
    let content = createCustomUpdateContentFromTextField()
    let completion: ((Result<Bool, CustomUpdateGraphRequestError>) -> Void) = { [weak self](result) in
      switch result {
      case .success(let success):
        self?.showAlert(message: "Custom update returned with success value: \(success)")
      case .failure(let error):
        self?.showAlert(message: "Error: \((error as NSError))")
      }
    }
    do {
      if let imageContent = content as? CustomUpdateContentImage {
        try CustomUpdateGraphRequest().request(content: imageContent, completionHandler: completion)
      } else if let mediaContent = content as? CustomUpdateContentMedia {
        try CustomUpdateGraphRequest().request(content: mediaContent, completionHandler: completion)
      }
    } catch CustomUpdateContentError.notInGameContext {
      self.showAlert(message: "Couldn't create a custom update request because you're not in a game context. Use the Create, Switch or Choose Context dialogs to join a game context.")
      return
    } catch {
      self.showAlert(message: " An error occured performing a Custom Update: \(error)")
      return
    }
  }

  func createCustomUpdateContentFromTextField() -> Any? {
    let customText =  customTextField.text?.isEmpty ?? true ?  "Come play this really cool game": customTextField.text!
    let ctaText = CTAField.text?.isEmpty ?? true ? "Join Game":CTAField.text!
    let gifURLText = gifURLField.text?.isEmpty ?? true ? "https://media.giphy.com/media/7ISIRaCMrgFfa/giphy.gif":gifURLField.text!
    let gifURL = URL(string: gifURLText)!
    let gifMedia = FacebookGIF(withUrl: gifURL)
    if let contextTokenID = contextTokenIDField.text, !contextTokenID.isEmpty {
      GamingContext.current = GamingContext(identifier: contextTokenID, size: 0)
    }

    if let selectedImage = imageView.image {
      let content = CustomUpdateContentImage(
        message: customText,
        image: selectedImage,
        cta: ctaText)
      return content
    }

    let content = CustomUpdateContentMedia(
      message: customText,
      media: gifMedia,
      cta: ctaText)
    return content
  }

   func showAlert(message: String) {
    let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
    self.present(alert, animated: true)
    Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
      alert.dismiss(animated: true)
    }
  }

  public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
    imageView.image = chosenImage

    dismiss(animated: true, completion: nil)
  }
}
