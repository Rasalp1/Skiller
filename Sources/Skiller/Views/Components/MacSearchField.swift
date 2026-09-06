import SwiftUI
import AppKit

public struct MacSearchField: NSViewRepresentable {
    @Binding public var text: String
    public var placeholder: String

    public init(text: Binding<String>, placeholder: String = "Search...") {
        self._text = text
        self.placeholder = placeholder
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = placeholder
        searchField.stringValue = text
        searchField.delegate = context.coordinator
        searchField.target = context.coordinator
        searchField.action = #selector(Coordinator.actionTriggered(_:))
        searchField.bezelStyle = .roundedBezel
        searchField.focusRingType = .none

        // Ensure window activates so user can immediately type
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            searchField.window?.makeKey()
            searchField.window?.makeFirstResponder(searchField)
        }

        return searchField
    }

    public func updateNSView(_ searchField: NSSearchField, context: Context) {
        if searchField.stringValue != text {
            searchField.stringValue = text
        }
    }

    @MainActor
    public final class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: MacSearchField

        init(_ parent: MacSearchField) {
            self.parent = parent
        }

        public func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSSearchField else { return }
            parent.text = field.stringValue
        }

        @objc func actionTriggered(_ sender: NSSearchField) {
            parent.text = sender.stringValue
        }
    }
}
