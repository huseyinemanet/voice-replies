import UIKit
import UserNotifications
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

extension Notification.Name {
    static let voiceRepliesQuickActionSelected = Notification.Name("voiceRepliesQuickActionSelected")
}

enum iOSQuickAction {
    static let recentReplyType = "com.local.voice-replies.recent-reply"
    static let replyUserInfoKey = "reply"
}

final class iOSQuickActionManager {
    static let shared = iOSQuickActionManager()

    private init() {}

    func refresh() {
        guard AppSettings.load().saveClipboardHistory else {
            UIApplication.shared.shortcutItems = nil
            return
        }

        let items = ClipboardHistoryStore.shared.items()
            .prefix(4)
            .map(shortcutItem)

        UIApplication.shared.shortcutItems = Array(items)
    }

    private func shortcutItem(for item: ClipboardHistoryItem) -> UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: iOSQuickAction.recentReplyType,
            localizedTitle: title(for: item.text),
            localizedSubtitle: timeFormatter.string(from: item.createdAt),
            icon: UIApplicationShortcutIcon(systemImageName: "doc.on.clipboard"),
            userInfo: [iOSQuickAction.replyUserInfoKey: item.text as NSString]
        )
    }

    private func title(for text: String) -> String {
        let singleLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard singleLine.count > 42 else { return singleLine }

        let endIndex = singleLine.index(singleLine.startIndex, offsetBy: 42)
        return String(singleLine[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

final class iOSQuickActionRouter {
    static let shared = iOSQuickActionRouter()

    private var pendingShortcutItem: UIApplicationShortcutItem?

    private init() {}

    func storePending(_ shortcutItem: UIApplicationShortcutItem) {
        pendingShortcutItem = shortcutItem
    }

    func deliverPendingIfNeeded() {
        guard let shortcutItem = pendingShortcutItem else { return }
        pendingShortcutItem = nil
        handle(shortcutItem)
    }

    @discardableResult
    func handle(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard shortcutItem.type == iOSQuickAction.recentReplyType,
              let reply = shortcutItem.userInfo?[iOSQuickAction.replyUserInfoKey] as? String,
              !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        NotificationCenter.default.post(
            name: .voiceRepliesQuickActionSelected,
            object: nil,
            userInfo: [iOSQuickAction.replyUserInfoKey: reply]
        )
        return true
    }
}

final class iOSAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        iOSNotificationPresenter.shared.prepare()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            iOSQuickActionRouter.shared.storePending(shortcutItem)
        }

        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = iOSSceneDelegate.self
        return configuration
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        iOSQuickActionManager.shared.refresh()
    }
}

extension iOSAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}

final class iOSSceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneDidBecomeActive(_ scene: UIScene) {
        iOSQuickActionRouter.shared.deliverPendingIfNeeded()
        iOSQuickActionManager.shared.refresh()
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(iOSQuickActionRouter.shared.handle(shortcutItem))
    }
}

final class iOSNotificationPresenter {
    static let shared = iOSNotificationPresenter()

    private init() {}

    func prepare() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }

            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
        }
    }

    func showCopiedNotification(reply: String) {
        let trimmedReply = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReply.isEmpty else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.deliverCopiedNotification(reply: trimmedReply)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, _ in
                    guard granted else { return }
                    self.deliverCopiedNotification(reply: trimmedReply)
                }
            default:
                return
            }
        }
    }

    private func deliverCopiedNotification(reply: String) {
        let content = UNMutableNotificationContent()
        content.title = "Copied"
        content.body = preview(for: reply)
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func preview(for text: String) -> String {
        let singleLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard singleLine.count > 120 else { return singleLine }

        let endIndex = singleLine.index(singleLine.startIndex, offsetBy: 120)
        return String(singleLine[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}
