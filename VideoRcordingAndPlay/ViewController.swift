//
//  ViewController.swift
//  VideoRcordingAndPlay
//
//  Created by Vadde Narendra on 5/6/20.
//  Copyright © 2020 Narendra Vadde. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var videoAndImageReview = UIImagePickerController()
    var videoURL : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            print("Camera Available")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera UnAvailable")
        }
        
    }
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
          dismiss(animated: true, completion: nil)
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaURL.rawValue] as? String,
              mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL.rawValue] as? URL,
              UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
              else {
                  return
          }
        
        // Handle a movie capture
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        videoAndImageReview.sourceType = .savedPhotosAlbum
        videoAndImageReview.delegate = self
        videoAndImageReview.mediaTypes = ["public.movie"]
        present(videoAndImageReview, animated: true, completion: nil)
    }
    
    func videoAndImageReview(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        videoURL = info[UIImagePickerController.InfoKey.mediaURL.rawValue] as? URL
           print("\(String(describing: videoURL))")
           self.dismiss(animated: true, completion: nil)
       }
}

