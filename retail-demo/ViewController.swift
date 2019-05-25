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
import WebKit
import Meridian

class ViewController: UIViewController, MRMapViewDelegate, MRLocationManagerDelegate, WKNavigationDelegate, WKUIDelegate {
    
    var mapView: MRMapView!
    var webView: WKWebView!
    var webViewConfig: WKWebViewConfiguration!
    var locationManager: MRLocationManager!
    let synthesizer = AVSpeechSynthesizer()
    let audioEngine = AVAudioEngine()
    let recognizer = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    var recordStatus: Bool = false
    
    let MAP_ID = "5764017373052928"
    let APP_ID = "5737079267393536"
    
    func mapPickerDidPick(_ map: MRMap) {
        
    }
    
    @IBOutlet weak var voiceButton: UIButton!
    @IBOutlet weak var spokenText: UILabel!
    
    override func loadView() {
        super.loadView()
        
        // Show WebKit view
        webViewConfig = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(origin: CGPoint.zero, size: self.view.frame.size), configuration: webViewConfig)
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        // self.view.addSubview(webView)
        // self.view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        locationManager = MRLocationManager(app: MREditorKey(identifier: APP_ID))
        locationManager.delegate = self
        
        mapView = MRMapView(frame: self.view.bounds)
        mapView.delegate = self
        
        mapView.mapKey = MREditorKey(forMap: MAP_ID, app: APP_ID)
        
        // Show Meridian map view
        // self.view.addSubview(mapView)
        
        voiceButton.layer.cornerRadius = voiceButton.frame.height/2
        voiceButton.layer.shadowOpacity = 0.75
        voiceButton.layer.shadowRadius = 5
            
        textToSpeech(text: "Welcome to meridian demo, have a great experience ahead")
    }

    override func viewDidAppear(_ animated: Bool) {
        let url = URL(string: "http://www.odishabytes.com/wp-content/uploads/2019/02/sunny-leone3.jpeg")!
        webView.load(URLRequest(url:url))
    }
    
    func startRecording(){
        let node = audioEngine.inputNode
        let format = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, _) in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch let error {
            print("Recording cannot be started\(error.localizedDescription)")
        }
        
        recognitionTask = recognizer?.recognitionTask(with: request) {
            (result, _) in
            if let transcription = result?.bestTranscription {
                print(transcription.formattedString)
                self.spokenText.text = transcription.formattedString
            }
        }
    }
    
    func stopRecording(){
        audioEngine.stop()
        request.endAudio()
        recognitionTask?.cancel()
    }
    
    @IBAction func voiceButtonClicked(_ sender: Any) {
        if (recordStatus){
            stopRecording()
            recordStatus = true
        }else{
            startRecording()
            recordStatus = false
        }
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

