import SwiftUI

@main
struct VoiceRepliesiOSApp: App {
    @UIApplicationDelegateAdaptor(iOSAppDelegate.self) private var appDelegate
    @StateObject private var viewModel = iOSVoiceReplyViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onOpenURL { url in
                    viewModel.handleShortcutURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .voiceRepliesQuickActionSelected)) { notification in
                    guard let reply = notification.userInfo?[iOSQuickAction.replyUserInfoKey] as? String else { return }
                    viewModel.copyReplyFromHistory(reply)
                }
                .onAppear {
                    iOSQuickActionManager.shared.refresh()
                }
        }
    }
}
