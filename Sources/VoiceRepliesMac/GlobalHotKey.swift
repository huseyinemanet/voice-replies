import AppKit
import Carbon.HIToolbox
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

final class GlobalHotKey {
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let shortcut: ShortcutOption
    private let onPressed: () -> Void

    init(shortcut: ShortcutOption, onPressed: @escaping () -> Void) {
        self.shortcut = shortcut
        self.onPressed = onPressed
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func register() throws {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()

                DispatchQueue.main.async {
                    hotKey.onPressed()
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            throw VoiceReplyError.hotKeyRegistrationFailed(handlerStatus)
        }

        let hotKeyID = EventHotKeyID(signature: fourCharCode("TVRP"), id: 1)
        let hotKeyStatus = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            UInt32(shortcut.modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard hotKeyStatus == noErr else {
            throw VoiceReplyError.hotKeyRegistrationFailed(hotKeyStatus)
        }
    }

    private func fourCharCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}

extension ShortcutOption {
    var keyCode: Int {
        switch self {
        case .controlOptionCommandSpace:
            return kVK_Space
        case .controlOptionCommandR:
            return kVK_ANSI_R
        case .controlOptionCommandReturn:
            return kVK_Return
        case .controlOptionCommandM:
            return kVK_ANSI_M
        }
    }

    var modifiers: Int {
        controlKey | optionKey | cmdKey
    }
}
