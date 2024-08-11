import Foundation
import FlutterMacOS
import WebKit
import SwiftUI
import WebKit


class MyMacosViewNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var mainView: SwiftUIView? = nil
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        mainView = SwiftUIView(
            frame: NSRect(x: 0, y: 0, width: 600, height: 600),  // Set an appropriate size
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
        
        return mainView!
    }
    
    
    func clickUpAt(x: Double, y: Double){
        
        guard let mainView = mainView else { return }
        
        let point = NSPoint(x: x, y: y)
        
        let mouseUpEvent = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: point,
            modifierFlags: [],
            timestamp: 0.1, // Slightly after mouse down
            windowNumber: mainView.window?.windowNumber ?? 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )
        mainView.mouseUp(with: mouseUpEvent!)
        
    }
    
    func clickDownAt(x: Double, y: Double) {
        guard let mainView = mainView else { return }
        
        let point = NSPoint(x: x, y: y)
        // Simulate mouse down
        let mouseDownEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: point,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: mainView.window?.windowNumber ?? 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )
        mainView.mouseDown(with: mouseDownEvent!)
    }
    
    func scroll(x: Double, y: Double, dy: Double){
        guard let mainView = mainView else { return }
        
        let point = CGPoint(x: x, y: y)
        
        let scrollEventCG = (CGEvent(scrollWheelEvent2Source: nil, units: CGScrollEventUnit.pixel, wheelCount: 1, wheel1: Int32(dy), wheel2: 0, wheel3: 0)!)
        
        scrollEventCG.location = point
                             
        let scrollEvent = NSEvent(cgEvent: scrollEventCG)
        

        mainView.scrollWheel(with: scrollEvent!)
    }
    
    func drag(x: Double, y: Double){
        guard let mainView = mainView else { return }
        
        let point = NSPoint(x: x, y: y)
        let mouseDragEvent = NSEvent.mouseEvent(
            with: .leftMouseDragged,
            location: point,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: mainView.window?.windowNumber ?? 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )
        
        mainView.mouseDragged(with: mouseDragEvent!)
    }
    
    func loadHtmlString(content: String){
        mainView?.loadHtmlString(content: content)
    }
    
    func resizeView(width: Double, height: Double){
        guard let mainView = mainView else { return }
        
        mainView.frame = NSRect(x: mainView.frame.origin.x, y: mainView.frame.origin.y, width: width, height: height)
        mainView.resizeSubviews(withOldSize: mainView.bounds.size)
    }
    
    func executeJS(js: String){
        
        mainView?.executeJS(js: js)
    }
}

class SwiftUIView: NSView, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var messenger: FlutterBinaryMessenger // Add this line
    
    init(
        frame: NSRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        self.messenger = messenger!
        super.init(frame: frame)
        
        initWebview()
    }
    
    func callbackSwiftToDart(methodName: String, message: String) {
        let channel = FlutterMethodChannel(name: "com.example/my_channel", binaryMessenger: messenger)
        
        channel.invokeMethod(methodName, arguments: message)
    }
    
    private func initWebview() {
        let contentController = WKUserContentController()
        contentController.add(
            self,
            name: "callbackHandler"
        )
        
        let userScript = WKUserScript(
            source: "window.webkit.messageHandlers.callbackHandler.postMessage('Hello from JavaScript from userScript')",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        contentController.addUserScript(userScript)
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        webView = WKWebView(frame: self.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        
        // add this link to https://cpstest.org/manual-click-test.php#google_vignette
        
        // webView.load(URLRequest(url: URL(string: "https://cpstest.org/manual-click-test.php#google_vignette")!))
        
//        webView.load(URLRequest(url: URL(string: "https://youtube.com")!))
        
        addSubview(webView)
        
        print("initWebview run finish")
    }
    
    // parameter is callback function
    func onJsCallback(message: String){
        print("onJsCallback run with message: \(message)")
        
        // add callback to array
        callbackSwiftToDart(methodName: "callback_from_js", message: message)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        onJsCallback(message: String(describing: message.body))
    }
    
    
    func loadHtmlString(content: String){
        print("loadHtmlString run")
        webView!.loadHTMLString(content, baseURL: nil)

        // try run code to callback to swift it self
        webView.evaluateJavaScript("window.webkit.messageHandlers.callbackHandler.postMessage('Hello from JavaScript from load HTML string')", completionHandler: nil)
        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func view() -> NSView {
        return self
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        webView.mouseDragged(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        // Handle mouse events
        super.mouseDown(with: event)
        
        // for warding event to webview
        webView.mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        // Handle mouse events
        super.mouseUp(with: event)
        
        // for warding event to webview
        webView.mouseUp(with: event)
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        
        webView.scrollWheel(with: event)
    }
    
    
    // execute js
    func executeJS(js: String){
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
class SwiftUIViewPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let factory = MyMacosViewNativeViewFactory(messenger: registrar.messenger)
        registrar.register(factory, withId: "MySwiftUiView")  // Make sure this matches your Flutter code
    }
}
