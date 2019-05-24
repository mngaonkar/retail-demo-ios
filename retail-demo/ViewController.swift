//
//  ViewController.swift
//  retail-demo
//
//  Created by mahadev gaonkar on 24/05/19.
//  Copyright © 2019 mahadev gaonkar. All rights reserved.
//

import UIKit
import AVFoundation
import Meridian

class ViewController: UIViewController, MRMapViewDelegate, MRLocationManagerDelegate {
    
    var mapView: MRMapView!
    var locationManager: MRLocationManager!
    let synthesizer = AVSpeechSynthesizer()
    
    let MAP_ID = "5764017373052928"
    let APP_ID = "5737079267393536"
    
    func mapPickerDidPick(_ map: MRMap) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        locationManager = MRLocationManager(app: MREditorKey(identifier: APP_ID))
        locationManager.delegate = self
        
        mapView = MRMapView(frame: self.view.bounds)
        // mapView.delegate = self
        
        mapView.mapKey = MREditorKey(forMap: MAP_ID, app: APP_ID)
        self.view.addSubview(mapView)
        
        speak(text: "Welcome to meridian demo, have a great day ahead")
    }

    func mapView(_ mapView: MRMapView, rendererFor overlay: MRPathOverlay) -> MRPathRenderer? {
        let renderer = MRPathRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.red
        return renderer
    }
    
    func locationManager(_ manager: MRLocationManager, didUpdateTo location: MRLocation) {
        
    }
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        synthesizer.speak(utterance)
    }
}

