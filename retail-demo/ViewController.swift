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
import ApiAI

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
    var timer: Timer!
    var recordStatus: Bool = false
    
    // Get follwing IDs from Meridian editor URL
    let MAP_ID = "5764017373052928"
    let APP_ID = "5737079267393536"
    
    func mapPickerDidPick(_ map: MRMap) {
        
    }
    
    @IBOutlet weak var voiceButton: UIButton!
    @IBOutlet weak var spokenText: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    // Load webkit view for rich media content
    func loadWebView() {
        // Show WebKit view
        webViewConfig = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(origin: CGPoint.zero, size: self.containerView.frame.size), configuration: webViewConfig)
        // webView = WKWebView()
        // webView = WKWebView(frame: .zero, configuration: webViewConfig)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(webView)
        
        print("Total subviews = \(self.view.subviews.count)")
        // let rootView = self.view.subviews[0]
        // webView.frame = rootView.bounds
        // rootView.addSubview(webView)
        // rootView.bringSubviewToFront(webView)
        
        //rootView.insertSubview(webView, at: 0)
        
        // loadURL(urlAddress: "https://cdn.pixabay.com/photo/2018/05/07/09/38/plants-3380443_960_720.jpg")
        loadURL(urlAddress: "https://www.reddit.com/")
    }
    
    // Open a dynamic web page in web view
    func loadURL(urlAddress: String) {
        let url = URL(string: urlAddress)!
        webView.load(URLRequest(url:url))
    }
    
    // Knock off web view out of sight
    func unloadWebView() {
        self.webView.removeFromSuperview()
    }
    
    // Here goes Meridian map
    func unloadMap() {
        self.mapView.removeFromSuperview()
    }
    
    // Load Meridian map view for indoor navigation
    func loadMap() {
        locationManager = MRLocationManager(app: MREditorKey(identifier: APP_ID))
        locationManager.delegate = self
        
        mapView = MRMapView(frame: self.containerView.bounds)
        mapView.delegate = self
        
        mapView.mapKey = MREditorKey(forMap: MAP_ID, app: APP_ID)
        
        // Show Meridian map view
        self.containerView.addSubview(mapView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        // loadMap()
        loadWebView()
        
        voiceButton.layer.cornerRadius = voiceButton.frame.height/2
        voiceButton.layer.shadowOpacity = 0.75
        voiceButton.layer.shadowRadius = 5
            
        // textToSpeech(text: "Welcome to meridian demo, have a great experience ahead")
    }

    override func viewDidAppear(_ animated: Bool) {
        if webView != nil {
            webView.uiDelegate = self
            webView.navigationDelegate = self
        }
        
    }
    
    // Reset the timer after few seconds so as not to keep the audio engine running
    func restartSpeechTimer(){
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (timer) in
            self.stopRecording()
        })
    }
    
    // Send request to Google Assistant and handle the response
    func sendRequest(textRequest: String){
        let request = ApiAI.shared()?.textRequest()
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            print("Response count = \(response.result.fulfillment.messages.count)")
            response.result.fulfillment.messages.forEach({ (item) in

                if item["type"] is String {
                    let responseType = item["type"] as! String
                    if responseType == "basic_card" {
                        let imageResponse = item["image"] as! NSDictionary
                        let url = imageResponse["url"] as! String
                        print("Image response from agent = \(url)")
                        self.loadURL(urlAddress: url)
                    } else if responseType == "simple_response" {
                        let textResponse = item["textToSpeech"] as! String
                        print("Text response from agent = \(textResponse)")
                        self.textToSpeech(text: textResponse)
                    }
                } else if item["type"] is Int {
                    let responseType = item["type"] as! Int
                    switch responseType {
                    case 0:
                        let textResponse = item["speech"] as! String
                        self.textToSpeech(text: textResponse)
                    default:
                        print("default case")
                    }
                }
                // print("Response platform = \(item["platform"] as! String)")
            })
        }, failure: { (request, error) in
            print(error!)
        })
        
        if textRequest != "" {
            request?.query = textRequest
            ApiAI.shared()?.enqueue(request)
        } else {
            return
        }
    }
    
    // Start listening to voice commands
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
            (result, error) in
            if let transcription = result?.bestTranscription {
                print("User request = \(transcription.formattedString)")
                
                self.spokenText.text = transcription.formattedString
                self.sendRequest(textRequest: self.spokenText.text!)
                // self.restartSpeechTimer()
                self.stopRecording()
                
                if (result?.isFinal)!{
                    print("Final transcript = \(transcription.formattedString)")
                }
                
                // Restart the voice recognition as we want to capture few words only
                if (error == nil){
                    self.restartSpeechTimer()
                }
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // Stop listening to user voice
    func stopRecording(){
        recognitionTask?.cancel()
        request.endAudio()
        audioEngine.stop()
        let node = audioEngine.inputNode
        node.removeTap(onBus: 0)
    }
    
    // Control the voice command button
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
    
    // Speak out the text received from Google Assistant
    func textToSpeech(text: String) {
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        let utterance = AVSpeechUtterance(string: text)
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
}

