import Cocoa
import SwiftUI
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    private var macosViewFactory: MyMacosViewNativeViewFactory?
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        registerPlugins(registry: controller)
        
        let channel = FlutterMethodChannel(name: "com.example/my_channel", binaryMessenger: controller.engine.binaryMessenger)
        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "click_down" {
                if let args = call.arguments as? String {
                    result("Received in Swift")
                    self.executeClickEventClickDown(command: args)
                }
            } else if (call.method == "click_up"){
                if let args = call.arguments as? String {
                    result("Received in Swift")
                    self.executeClickEventClickUp(command: args)
                }
            } else if (call.method == "load_html_string") {
                if let args = call.arguments as? String {
                    self.loadHtmlString(content: args)
                }
            } else if(call.method == "change_view_size"){
                if let args = call.arguments as? String {
                    self.changeViewSize(command: args)
                }
            } else if (call.method == "execute_script"){
                if let args = call.arguments as? String {
                    self.macosViewFactory?.executeJS(js: args)
                }
            } else if(call.method == "mouse_scroll"){
                if let args = call.arguments as? String {
                    self.mouseScroll(command: args)
                }
            } else if (call.method == "mouse_drag") {
                if let args = call.arguments as? String {
                    self.mouseDrag(command: args)
                }
            } else if (call.method == "get_device_list") {
                let deviceList = self.getListOfAudioInputDevice()
                result(deviceList)
            } else if (call.method == "get_obs_apple_path") {
                let path = Bundle.main.path(forResource: "obs_apple", ofType: "app")
                result(path)
            } else if (call.method == "get_obs_intel_path") {
                let path = Bundle.main.path(forResource: "obs_intel", ofType: "app")
                result(path)
            } else if (call.method == "get_bundle_resource_path") {
                let path = Bundle.main.resourcePath
                result(path)
            }
            else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    private func getListOfAudioInputDevice() -> String {
        var deviceList: [[String: String]] = []
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)
        if status != noErr {
            print("Error in getting property data size")
            return "";
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var audioDevices = [AudioDeviceID](repeating: 0, count: deviceCount)
        status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &audioDevices)
        if status != noErr {
            print("Error in getting property data")
            return "";
        }
        
        for device in audioDevices {
            // Check if the device is an input device
            var streamPropertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioObjectPropertyScopeInput,
                mElement: kAudioObjectPropertyElementMaster
            )
            
            var streamDataSize: UInt32 = 0
            status = AudioObjectGetPropertyDataSize(device, &streamPropertyAddress, 0, nil, &streamDataSize)
            if status != noErr || streamDataSize == 0 {
                // Skip this device if it's not an input device or if an error occurred
                continue
            }
            
            // Device is an input device, proceed to get its name and UID
            var devicePropertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster
            )
            
            var name: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            status = AudioObjectGetPropertyData(device, &devicePropertyAddress, 0, nil, &nameSize, &name)
            if status == noErr {
                var uid: CFString = "" as CFString
                var uidSize = UInt32(MemoryLayout<CFString>.size)
                devicePropertyAddress.mSelector = kAudioDevicePropertyDeviceUID
                status = AudioObjectGetPropertyData(device, &devicePropertyAddress, 0, nil, &uidSize, &uid)
                if status == noErr {
                    print("Device ID: \(uid), Device Name: \(name)")
                    // Add device id and device name to list as dictionary
                    deviceList.append(["id": String(uid), "name": String(name)])
                }
            }
        }
        
        // convert device list to json string and return
        let jsonData = try! JSONSerialization.data(withJSONObject: deviceList, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)
        return jsonString!
    }
    
    func mouseDrag(command: String) {
        let scrollData = convertStringToDictionary(data: command)

        let x = (scrollData["x"] as! NSNumber).doubleValue
        let y = (scrollData["y"] as! NSNumber).doubleValue
        macosViewFactory?.drag(x: x, y: y)
    }
    
    
    func mouseScroll(command: String){
        let scrollData = convertStringToDictionary(data: command)
        
        let x = (scrollData["x"] as! NSNumber).doubleValue
        let y = (scrollData["y"] as! NSNumber).doubleValue
        let dy = (scrollData["delta"] as! NSNumber).doubleValue
        macosViewFactory?.scroll(x: x, y: y, dy: dy)
    }
    
    func changeViewSize(command: String){
        let viewSizeData = convertStringToDictionary(data: command)
        
        let width = (viewSizeData["width"] as! NSNumber).doubleValue
        let height = (viewSizeData["height"] as! NSNumber).doubleValue
        
        macosViewFactory?.resizeView(width: width, height: height)
    }
    
    func loadHtmlString(content: String){
        macosViewFactory?.loadHtmlString(content: content)
    }
    
    func convertStringToDictionary(data: String) -> [String: Any] {
        if let data = data.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
            } catch {
                print(error.localizedDescription)
            }
        }
        return [:]
    }
    
    private func executeClickEventClickUp(command: String){
        let coordinationData = convertStringToDictionary(data: command)
        let x = (coordinationData["x"] as! NSNumber).doubleValue
        
        // get view high
        let viewHeight = mainFlutterWindow?.contentViewController?.view.frame.height ?? 0
        let y = viewHeight - (coordinationData["y"] as! NSNumber).doubleValue
        
        // call function from MyMacosViewNativeViewFactory
        macosViewFactory?.clickUpAt(x: x, y: y)
    }
    
    private func executeClickEventClickDown(command: String){
        let coordinationData = convertStringToDictionary(data: command)
        let x = (coordinationData["x"] as! NSNumber).doubleValue
        
        // get view high
        let viewHeight = mainFlutterWindow?.contentViewController?.view.frame.height ?? 0
        let y = viewHeight - (coordinationData["y"] as! NSNumber).doubleValue
        
        // call function from MyMacosViewNativeViewFactory
        macosViewFactory?.clickDownAt(x: x, y: y)
    }
    
    private func registerPlugins(registry: FlutterPluginRegistry) {
        let registrar = registry.registrar(forPlugin: "MyMacosViewNativeViewFactory")
        macosViewFactory = MyMacosViewNativeViewFactory(messenger: registrar.messenger)
        
        registrar.register(macosViewFactory!, withId: "MySwiftUiView")
    }
    
}
