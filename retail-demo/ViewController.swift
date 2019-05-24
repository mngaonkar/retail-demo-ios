//
//  ViewController.swift
//  retail-demo
//
//  Created by mahadev gaonkar on 24/05/19.
//  Copyright © 2019 mahadev gaonkar. All rights reserved.
//

import UIKit
import Meridian

class ViewController: UIViewController, MRMapViewDelegate {
    
    var config: MRConfig!
    var mapView: MRMapView!
    var appKey: MREditorKey!
    
    func mapPickerDidPick(_ map: MRMap) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        mapView = MRMapView(frame: self.view.bounds)
        mapView.mapKey = MREditorKey(forMap: "5764017373052928", app: "5737079267393536")
        self.view.addSubview(mapView)
        
    }


}

