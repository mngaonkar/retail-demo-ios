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
    var currentView: UIView!
    
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
        webViewConfig.allowsInlineMediaPlayback = true
        webViewConfig.allowsAirPlayForMediaPlayback = true
        webViewConfig.allowsPictureInPictureMediaPlayback = true
        webViewConfig.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: CGRect(origin: CGPoint.zero, size: self.containerView.frame.size), configuration: webViewConfig)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(webView)
        self.currentView = webView
        
        print("Total subviews = \(self.view.subviews.count)")
        // let rootView = self.view.subviews[0]
        webView.frame = self.containerView.bounds
        // rootView.addSubview(webView)
        // rootView.bringSubviewToFront(webView)
        
        //rootView.insertSubview(webView, at: 0)
        
        loadURL(urlAddress: "https://storage.googleapis.com/retail-kiosk.appspot.com/introduction.html")
    }
    
    func animateView(view: UIView, hidden: Bool) {
        UIView.transition(with: view, duration: 0.5, options: [.transitionFlipFromRight], animations: {
            view.isHidden = hidden
        }, completion: nil)
    }
    
    // Load HTML content
    func loadHTML(content: String) {
        animateView(view: webView, hidden: true)
        webView.loadHTMLString(content, baseURL: Bundle.main.bundleURL)
        animateView(view: webView, hidden: false)
    }
    
    // Open a dynamic web page in web view
    func loadURL(urlAddress: String) {
        let url = URL(string: urlAddress)!
        animateView(view: webView, hidden: true)
        webView.load(URLRequest(url:url))
        animateView(view: webView, hidden: false)
    }
    
    // Knock off web view out of sight
    func unloadWebView() {
        self.webView.removeFromSuperview()
        self.currentView = nil
    }
    
    // Here goes Meridian map
    func unloadMap() {
        self.mapView.removeFromSuperview()
        self.currentView = nil
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
        self.currentView = mapView
    }
    
    // Create additional widget here
    override func viewDidLoad() {
        super.viewDidLoad()
    
        print("View did load")
        // Do any additional setup after loading the view.
        // loadMap()
        // loadWebView()
        
        voiceButton.layer.cornerRadius = voiceButton.frame.height/2
        voiceButton.layer.shadowOpacity = 0.75
        voiceButton.layer.shadowRadius = 3
        
        // spokenText.textAlignment = .center
        // spokenText.textColor = UIColor.blue
        
        // textToSpeech(text: "Welcome to meridian demo, have a great experience ahead")
    }

    // Put all the view related code here
    override func viewDidAppear(_ animated: Bool) {
        print("View did appear")
        loadWebView()
        
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
    
    // Image response
    func handleBasicCardResponse(item: [AnyHashable:Any]) {
        print("basic card response received")
        let imageResponse = item["image"] as! NSDictionary
        let url = imageResponse["url"] as! String
        print("Image response from agent = \(url)")
        if self.currentView != self.webView {
            unloadMap()
            loadWebView()
        }
        
        self.loadURL(urlAddress: url)
    }
    
    // Simple text response
    func handleSimpleResponse(item: [AnyHashable:Any]) {
        print("simple response received")
        let textResponse = item["textToSpeech"] as! String
        print("Text response from agent = \(textResponse)")
        self.textToSpeech(text: textResponse)
    }
    
    // Custom response
    func handleCustomPayloadResponse(item: [AnyHashable:Any]) {
        print("custom response received")
        let customResponse = item["payload"] as! NSDictionary
        let payload = customResponse["google"] as! NSDictionary
        
        if payload["movie"] != nil {
            let url = payload["movie"] as! String
            print("Movie response from agent = \(url)")
            if self.currentView != self.webView {
                unloadMap()
                loadWebView()
            }
            
            self.loadURL(urlAddress: url)
        } else if payload["directions"] != nil {
            unloadWebView()
            loadMap()
        }
        
    }
    
    // Send request to Google Assistant and handle the response
    func sendRequest(textRequest: String){
        var textResponseReceived = false
        
        let request = ApiAI.shared()?.textRequest()
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            print("Response count = \(response.result.fulfillment.messages.count)")
            response.result.fulfillment.messages.forEach({ (item) in

                if item["type"] is String {
                    let responseType = item["type"] as! String
                    if responseType == "basic_card" {
                        self.handleBasicCardResponse(item: item)
                    } else if responseType == "simple_response" {
                        self.handleSimpleResponse(item: item)
                        textResponseReceived = true
                    } else if responseType == "custom_payload" {
                        self.handleCustomPayloadResponse(item: item)
                    }else {
                        print("Unknown response type = \(responseType)")
                    }
                } else if item["type"] is Int {
                    let responseType = item["type"] as! Int
                    print("response type received = \(responseType)")
                    switch responseType {
                    case 0:
                        let textResponse = item["speech"] as! String
                        print("Text response from agent = \(textResponse)")
                        if !textResponseReceived {
                            self.textToSpeech(text: textResponse)
                        }
                    case 1:
                        let content = """
                        <p style="font-size:600%;"> \(item["title"] as! String) </p>
                        <img width=100% src = "\(item["imageUrl"] as! String)"</img>
                        """
                        let url = item["imageUrl"] as! String
                            
                        print("Image response from agent = \(url)")
                        if self.currentView != self.webView {
                            self.unloadMap()
                            self.loadWebView()
                        }
                        
                        self.loadHTML(content: content)
                        // self.loadURL(urlAddress: url)
                        // self.textToSpeech(text: item["text"] as! String)
                        
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
        print("Starting recording")
        let node = audioEngine.inputNode
        // let format = node.outputFormat(forBus: 0)
        // let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        let format = AVAudioFormat(standardFormatWithSampleRate: audioEngine.inputNode.inputFormat(forBus: 0).sampleRate, channels: 1)
        
        
        node.installTap(onBus: 0, bufferSize: 4096, format: format) { (buffer, _) in
            self.request.append(buffer)
        }
        print("Tap installed")
        
        audioEngine.prepare()
        print("Audio engine prepared")
        
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
                // self.stopRecording()
                // self.spokenText.text = transcription.formattedString
                // self.sendRequest(textRequest: self.spokenText.text!)
                // self.restartSpeechTimer()
                
                
                if (result?.isFinal)!{
                    print("Final transcript = \(transcription.formattedString)")
                    self.stopRecording()
                    self.spokenText.text = transcription.formattedString
                    self.sendRequest(textRequest: self.spokenText.text!)
                }
                
                // Restart the voice recognition as we want to capture few words only
                if (error == nil){
                    self.restartSpeechTimer()
                    print("Started wait time for conversation")
                }
            } else if let error = error {
                print("Error occured during recognition = \(error)")
                self.textToSpeech(text: "seems like we are timing out here, bye!")
                self.stopRecording()
            }
        }
        print("Recording started")
        self.recordStatus = true
    }
    
    // Stop listening to user voice
    func stopRecording(){
        print("Stoping recording...")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.finish()
        request.endAudio()
        print("Recording stopped")
        self.recordStatus = false
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
    
    // Get the current user location
    func locationManager(_ manager: MRLocationManager, didUpdateTo location: MRLocation) {
        print("Location update is x = \(location.point.x) y = \(location.point.y)")
    }
    
    // Speak out the text received from Google Assistant
    func textToSpeech(text: String) {
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        let utterance = AVSpeechUtterance(string: text)
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
    
    // Orientation has changed, resize the views
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("Orientation changed")
        super.viewWillTransition(to: size, with: coordinator)
        // self.webView.frame = self.containerView.frame
    }
}

