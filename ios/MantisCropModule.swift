import Foundation
import Photos
import UIKit
import React
import Mantis
import BSImagePicker

@objc(MantisCropModule)
class MantisCropModule: NSObject, RCTBridgeModule, CropViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImagePickerControllerDelegate {
  func imagePicker(_ imagePicker: BSImagePicker.ImagePickerController, didSelectAsset asset: PHAsset) {
      // Your code for when an asset is selected
  }

  func imagePicker(_ imagePicker: BSImagePicker.ImagePickerController, didDeselectAsset asset: PHAsset) {
      // Your code for when an asset is deselected
  }

  func imagePicker(_ imagePicker: BSImagePicker.ImagePickerController, didFinishWithAssets assets: [PHAsset]) {
    var base64ImageList: [String] = []
    
    let group = DispatchGroup()
    
    for asset in assets {
        group.enter()
        
        PHImageManager.default().requestImageData(for: asset, options: nil) { (data, _, _, _) in
            if let imageData = data, let image = UIImage(data: imageData) {
                if let base64String = image.jpegData(compressionQuality: 1.0)?.base64EncodedString(options: .lineLength64Characters) {
                    base64ImageList.append(base64String)
                }
            }
            
            group.leave()
        }
    }
    
    group.notify(queue: DispatchQueue.main) {
        self.base64ImageCallback?([base64ImageList])
    }
}

  func imagePicker(_ imagePicker: BSImagePicker.ImagePickerController, didCancelWithAssets assets: [PHAsset]) {
      // Your code for when the image picker is canceled
  }

  func imagePicker(_ imagePicker: BSImagePicker.ImagePickerController, didReachSelectionLimit count: Int) {
      // Your code for when the selection limit is reached
  }

  
    
    static func moduleName() -> String {
        return "MantisCropModule"
    }
    
    var croppedImageCompletion: ((UIImage) -> Void)?
    private var base64ImageCallback: RCTResponseSenderBlock?
    
    @objc func setBase64ImageCallback(_ callback: @escaping RCTResponseSenderBlock) {
        base64ImageCallback = callback
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
        croppedImageCompletion?(cropped)
        
        // Convert the cropped image to base64 with the correct format
        if let imageData = cropped.jpegData(compressionQuality: 1.0) {
            let base64String =  imageData.base64EncodedString(options: .lineLength64Characters)
            print("Base64 representation of the cropped image:\n\(base64String)")
            
            // Send the image URL to React Native
            base64ImageCallback?([base64String])
        } else {
            print("Failed to convert the cropped image to base64.")
            base64ImageCallback?(["Failed to convert the cropped image to base64."])
        }
        
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true, completion: nil)
    }

private var selectedImages: [UIImage] = []

@objc func openImagePickerForMultipleImages(_ callback: @escaping RCTResponseSenderBlock) {
    let imagePicker = ImagePickerController()
    imagePicker.settings.selection.max = 10 // Set the maximum number of images you want to allow

    guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
        return
    }

    imagePicker.imagePickerDelegate = self

    DispatchQueue.main.async {
        viewController.present(imagePicker, animated: true, completion: nil)
    }

    // Store the callback to send the base64 image list back to React Native
    base64ImageCallback = callback
}
    @objc func openImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            return
        }
        
        DispatchQueue.main.async {
            viewController.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func openMantisCropWithURL(_ imageURL: String) {
        guard let url = URL(string: imageURL) else {
            print("Invalid URL provided: \(imageURL)")
            return
        }
        openMantisCrop(selectedImageURL: url)
    }

    private func openMantisCrop(selectedImageURL: URL) {
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            return
        }

        if selectedImageURL.isFileURL {
            if let image = UIImage(contentsOfFile: selectedImageURL.path) {
                presentCropViewController(viewController: viewController, image: image)
            }
        } else {
            URLSession.shared.dataTask(with: selectedImageURL) { data, _, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.presentCropViewController(viewController: viewController, image: image)
                    }
                }
            }.resume()
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            if let imageURL = info[.imageURL] as? URL {
                openMantisCrop(selectedImageURL: imageURL)
            }
            presentCropViewController(viewController: picker, image: selectedImage)
        } else {
            print("Failed to select an image.")
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    private func presentCropViewController(viewController: UIViewController, image: UIImage) {
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = self
        
        if #available(iOS 13.0, *) {
            cropViewController.modalPresentationStyle = .fullScreen
        }
        
        DispatchQueue.main.async {
            viewController.present(cropViewController, animated: true)
        }
    }
}
