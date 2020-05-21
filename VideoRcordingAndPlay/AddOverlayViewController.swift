//
//  AddOverlayViewController.swift
//  VideoRcordingAndPlay
//
//  Created by Vadde Narendra on 5/6/20.
//  Copyright © 2020 Narendra Vadde. All rights reserved.
//

import UIKit
import AVFoundation

class AddOverlayViewController: CommonVideoViewController {
    
@IBOutlet weak var frameSelectSegment: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func loadAsset(_ sender: Any) {
        startMediaBrowser(from: self, usingDelegate: self)
    }

    @IBAction func generateOutput(_ sender: Any) {
        videoOutput()
    }

    override func applyVideoEffects(to composition: AVMutableVideoComposition?, size: CGSize) {
    }

}
