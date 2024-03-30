import Flutter
import UIKit
import MobileCoreServices

public class DesktopDropPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "desktop_drop", binaryMessenger: registrar.messenger())
        let instance = DesktopDropPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let viewfactory = DropTargetFactory(channel: channel, messenger: registrar.messenger())
        registrar.register(viewfactory, withId: "DropTarget")
    }
}

public class DropTargetFactory: NSObject, FlutterPlatformViewFactory{
    
    private var channel: FlutterMethodChannel
    private var messenger: FlutterBinaryMessenger
    
    init(channel: FlutterMethodChannel, messenger: FlutterBinaryMessenger) {
        self.channel = channel
        self.messenger = messenger
        super.init()
    }
    
    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return DropTarget(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
            channel: channel)
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
public class DropTarget: NSObject, FlutterPlatformView, UIDropInteractionDelegate {
    private var _view: UIView
    let viewId: Int64
    let messenger: FlutterBinaryMessenger
    let channel: FlutterMethodChannel
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger,
        channel: FlutterMethodChannel
    ) {
        self.messenger = messenger
        self.viewId = viewId
        _view = UIView()
        self.channel = channel
        
        super.init()
        
        channel.setMethodCallHandler(handle)
        let dropInteraction = UIDropInteraction(delegate: self)
        _view.addInteraction(dropInteraction)
    }
    
    
    public func view() -> UIView {
        return _view
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableDrop":
            setupDragInteraction()
            result(nil)
        case "disableDrop":
            removeDragInteraction()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func customEnableDropping(on view: UIView, dropInteractionDelegate: UIDropInteractionDelegate) {
        let dropInteraction = UIDropInteraction(delegate: dropInteractionDelegate)
        view.addInteraction(dropInteraction)
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeFileURL as String])
    }
    
    // Handle drag enter event
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        channel.invokeMethod("entered", arguments: nil)
    }
    
    // Handle drag location update event
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        channel.invokeMethod("updated", arguments: nil)
        return UIDropProposal(operation: .copy)
    }
    
    // Handle drag exit event
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        channel.invokeMethod("exited", arguments: nil)
    }
    
    // Handle drop event
    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        handleDrop(session)
    }
    
    private func setupDragInteraction() {
        let dropInteraction = UIDropInteraction(delegate: self)
        _view.addInteraction(dropInteraction)
    }
    
    private func removeDragInteraction() {
        if let interaction = _view.interactions.first(where: { $0 is UIDropInteraction }) {
            _view.removeInteraction(interaction)
        }
    }
    
    private func handleDrop(_ session: UIDropSession) {
        guard session.hasItemsConforming(toTypeIdentifiers: [kUTTypeFileURL as String]) else { return }
        
        session.loadObjects(ofClass: NSURL.self) { items in
            let urls = items.compactMap { ($0 as? URL)?.absoluteString }
            self.channel.invokeMethod("performOperation", arguments: urls)
        }
    }
}


