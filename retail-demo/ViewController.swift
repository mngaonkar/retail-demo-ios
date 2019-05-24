//
//  ViewController.swift
//  retail-demo
//
//  Created by mahadev gaonkar on 24/05/19.
//  Copyright © 2019 mahadev gaonkar. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import Meridian

class ViewController: UIViewController, MRMapViewDelegate, MRLocationManagerDelegate {
    
    var mapView: MRMapView!
    var locationManager: MRLocationManager!
    let synthesizer = AVSpeechSynthesizer()
    let audioEngine = AVAudioEngine()
    let recognizer = SFSpeechRecognizer()
    
    let MAP_ID = "5764017373052928"
    let APP_ID = "5737079267393536"
    
    func mapPickerDidPick(_ map: MRMap) {
        
    }
    
    @IBOutlet weak var voiceButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        locationManager = MRLocationManager(app: MREditorKey(identifier: APP_ID))
        locationManager.delegate = self
        
        mapView = MRMapView(frame: self.view.bounds)
        mapView.delegate = self
        
        mapView.mapKey = MREditorKey(forMap: MAP_ID, app: APP_ID)
        
        // self.view.addSubview(mapView)
        voiceButton.layer.cornerRadius = voiceButton.frame.height/2
        voiceButton.layer.shadowOpacity = 0.75
        voiceButton.layer.shadowRadius = 5
            
        textToSpeech(text: "Welcome to meridian demo, have a great day ahead")
    }

    @IBAction func voiceButtonClicked(_ sender: Any) {
        
    }
    
    func mapView(_ mapView: MRMapView, rendererFor overlay: MRPathOverlay) -> MRPathRenderer? {
        let renderer = MRPathRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.red
        return renderer
    }
    
    func locationManager(_ manager: MRLocationManager, didUpdateTo location: MRLocation) {
        
    }
    
    func textToSpeech(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        synthesizer.speak(utterance)
    }
}

