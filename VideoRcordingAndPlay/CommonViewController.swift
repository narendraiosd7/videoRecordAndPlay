//
//  CommonViewController.swift
//  VideoRcordingAndPlay
//
//  Created by Vadde Narendra on 5/6/20.
//  Copyright © 2020 Narendra Vadde. All rights reserved.
//

import Photos
import AVFoundation
import MobileCoreServices
import UIKit


class CommonVideoViewController: UIViewController, UIAlertViewDelegate {
    
    var videoAsset: AVAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func startMediaBrowser(from controller: UIViewController?, usingDelegate delegate: Any?) -> Bool {
        // 1 - Validations
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == false) || (delegate == nil) || (controller == nil) {
            return false
        }
        
        // 2 - Get image picker
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .photoLibrary
        mediaUI.mediaTypes = [kUTTypeMovie as String]
        // Hides the controls for moving & scaling pictures, or for
        // trimming movies. To instead show the controls, use YES.
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate as? (UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        
        // 3 - Display image picker
        controller?.present(mediaUI, animated: true)
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 1 - Get media type
        let mediaType = info[.mediaType] as? String
        
        // 2 - Dismiss image picker
        dismiss(animated: true)
        
        // 3 - Handle video selection
        if CFStringCompare(mediaType as CFString?, kUTTypeMovie, []) == .compareEqualTo {
            if let object = info[.mediaURL] as? URL {
                videoAsset = AVAsset(url: object)
            }
            let alert = UIAlertView(title: "Asset Loaded", message: "Video Asset Loaded", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            alert.show()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    func applyVideoEffects(to composition: AVMutableVideoComposition?, size: CGSize) {
        // no-op - override this method in the subclass
    }
    
    func videoOutput() {
        // 1 - Early exit if there's no video file selected
        if !(videoAsset != nil) {
            let alert = UIAlertController(title: "Error", message: "Please Load a Video Asset First", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 3 - Video track
        let videoTrack = mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoTrack?.insertTimeRange(
                CMTimeRangeMake(start: .zero, duration: videoAsset!.duration),
                of: videoAsset!.tracks(withMediaType: .video)[0],
                at: .zero)
        } catch {
        }
        
        // 3.1 - Create AVMutableVideoCompositionInstruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoAsset!.duration)
        
        // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
        let videolayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
        let videoAssetTrack = videoAsset!.tracks(withMediaType: .video)[0]
        var videoAssetOrientation_: UIImage.Orientation = .up
        var isVideoAssetPortrait_ = false
        let videoTransform = videoAssetTrack.preferredTransform
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ = .right
            isVideoAssetPortrait_ = true
        }
        
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ = UIImage.Orientation.left
            isVideoAssetPortrait_ = true
        }
        
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            videoAssetOrientation_ = UIImage.Orientation.up
        }
        
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            videoAssetOrientation_ = UIImage.Orientation.down
        }
        
        videolayerInstruction.setTransform(videoAssetTrack.preferredTransform, at: .zero)
        videolayerInstruction.setOpacity(0.0, at: videoAsset!.duration)
        
        // 3.3 - Add instructions
        if let array = [videolayerInstruction] as? [AVVideoCompositionLayerInstruction] {
            mainInstruction.layerInstructions = array
        }
        
        let mainCompositionInst = AVMutableVideoComposition()
        
        var naturalSize: CGSize
        if isVideoAssetPortrait_ {
            naturalSize = CGSize(width: videoAssetTrack.naturalSize.height, height: videoAssetTrack.naturalSize.width)
        } else {
            naturalSize = videoAssetTrack.naturalSize
        }
        
        var renderWidth: Float
        var renderHeight: Float
        renderWidth = Float(naturalSize.width)
        renderHeight = Float(naturalSize.height)
        mainCompositionInst.renderSize = CGSize(width: CGFloat(renderWidth), height: CGFloat(renderHeight))
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        applyVideoEffects(to: mainCompositionInst, size: naturalSize)
        
        // 4 - Get path
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)
        let documentsDirectory = paths[0]
        let myPathDocs = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("FinalVideo-\(arc4random() % 1000).mov").absoluteString
        let url = URL(fileURLWithPath: myPathDocs)
        
        // 5 - Create exporter
        let exporter = AVAssetExportSession(
            asset: mixComposition,
            presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = url
        exporter?.outputFileType = .mov
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainCompositionInst
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async(execute: {
                exportDidFinish(exporter)
            })
        })
        
        func exportDidFinish(_ session: AVAssetExportSession?) {
            if session?.status == .completed {
                let outputURL = session?.outputURL
                let library = PHPhotoLibrary()
                if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: outputURL) {
                    library.writeVideoAtPath(toSavedPhotosAlbum: outputURL, completionBlock: { assetURL, error in
                        DispatchQueue.main.async(execute: {
                            if error != nil {
                                let alert = UIAlertView(title: "Error", message: "Video Saving Failed", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
                                alert.show()
                            } else {
                                let alert = UIAlertView(title: "Video Saved", message: "Saved To Photo Album", delegate: self, cancelButtonTitle: "OK", otherButtonTitles: "")
                                alert.show()
                            }
                        })
                    })
                }
                
            }
        }
        
    }
}
