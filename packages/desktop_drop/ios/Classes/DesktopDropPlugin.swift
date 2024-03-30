import Flutter
import UIKit
import MobileCoreServices

public class DesktopDropPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private weak var view: UIView?

    // Initializer is now private to enforce factory method usage
    private override init() {
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "desktop_drop", binaryMessenger: registrar.messenger())
        let instance = DesktopDropPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        // Assuming the view to add drag interaction is the registrar's view
//         if let view = registrar.view() {
//             instance.setView(view)
//         }
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

    private func setView(_ view: UIView) {
        self.view = view
    }

    private func setupDragInteraction() {
        guard let view = view else { return }
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
    }

    private func removeDragInteraction() {
        guard let view = view else { return }
        if let interaction = view.interactions.first(where: { $0 is UIDropInteraction }) {
            view.removeInteraction(interaction)
        }
    }

    private func handleDrop(_ session: UIDropSession) {
        guard let channel = channel else { return }
        guard session.hasItemsConforming(toTypeIdentifiers: [kUTTypeFileURL as String]) else { return }

        session.loadObjects(ofClass: NSURL.self) { items in
            let urls = items.compactMap { ($0 as? URL)?.absoluteString }
            channel.invokeMethod("performOperation", arguments: urls)
        }
    }
}

extension DesktopDropPlugin: UIDropInteractionDelegate {
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeFileURL as String])
    }

    // Handle drag enter event
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        channel?.invokeMethod("entered", arguments: nil)
    }

    // Handle drag location update event
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        channel?.invokeMethod("updated", arguments: nil)
        return UIDropProposal(operation: .copy)
    }

    // Handle drag exit event
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        channel?.invokeMethod("exited", arguments: nil)
    }

    // Handle drop event
    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        handleDrop(session)
    }
}
