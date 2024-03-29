import Flutter
import UIKit

public class DesktopDropPlugin: NSObject {
    private var channel: FlutterMethodChannel?
    private weak var view: UIView?
    private weak var viewController: UIViewController?

    public init(with registrar: FlutterPluginRegistrar) {
        super.init()
        channel = FlutterMethodChannel(name: "desktop_drop", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(self, channel: channel!)
    }

    public func setView(_ view: UIView?, viewController: UIViewController?) {
        self.view = view
        self.viewController = viewController
        setupDragInteraction()
    }

    private func setupDragInteraction() {
        guard let view = view else { return }
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
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

extension DesktopDropPlugin: FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = DesktopDropPlugin(with: registrar)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }
}

extension DesktopDropPlugin: UIDropInteractionDelegate {
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
}
