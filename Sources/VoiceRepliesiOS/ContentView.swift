import SwiftUI
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

struct ContentView: View {
    @ObservedObject var viewModel: iOSVoiceReplyViewModel
    @State private var pulse = false
    @State private var isHistoryEnabled = AppSettings.load().saveClipboardHistory
    @State private var didHandleLaunchRecording = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Button {
                    toggleRecording()
                } label: {
                    ZStack {
                        if !viewModel.isRecording && !viewModel.isProcessing {
                            IdleRippleView()
                        }

                        if viewModel.isRecording {
                            Circle()
                                .stroke(.red.opacity(0.34), lineWidth: 3)
                                .frame(width: 190, height: 190)
                                .scaleEffect(pulse ? 1.24 : 0.98)
                                .opacity(pulse ? 0 : 0.7)
                                .animation(
                                    .easeOut(duration: 1.15)
                                        .repeatForever(autoreverses: false),
                                    value: pulse
                                )

                            Circle()
                                .fill(.red.opacity(0.14))
                                .frame(width: 196, height: 196)
                                .scaleEffect(pulse ? 1.08 : 0.94)
                                .animation(
                                    .easeInOut(duration: 0.9)
                                        .repeatForever(autoreverses: true),
                                    value: pulse
                                )
                        }

                        Circle()
                            .fill(buttonFill)
                            .frame(width: 172, height: 172)
                            .shadow(color: .black.opacity(0.16), radius: 20, y: 10)

                        if viewModel.isProcessing {
                            ProcessingSpinnerIcon()
                        } else {
                            Image(systemName: buttonSymbol)
                                .font(.system(size: 58, weight: .semibold))
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(0))
                        }
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(viewModel.isRecording ? 0.96 : 1)
                .animation(.snappy(duration: 0.16), value: viewModel.isRecording)
                .disabled(viewModel.isProcessing)
                .onAppear {
                    guard viewModel.isRecording else { return }

                    DispatchQueue.main.async {
                        pulse = true
                    }
                }
                .onChange(of: viewModel.isRecording) { _, isRecording in
                    pulse = false
                    guard isRecording else { return }

                    DispatchQueue.main.async {
                        pulse = true
                    }
                }

                VStack(spacing: 8) {
                    Text(displayStatusText)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(primaryStatusColor)
                }

                if !viewModel.lastReply.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last copied")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.lastReply)
                            .font(.body)
                            .lineLimit(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .navigationTitle("Voice Replies")
            .toolbar {
                if isHistoryEnabled {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            iOSHistoryView(viewModel: viewModel)
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        iOSSettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                refreshHistoryVisibility()
                startRecordingOnLaunchIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .voiceReplySettingsDidChange)) { _ in
                refreshHistoryVisibility()
            }
        }
    }

    private func refreshHistoryVisibility() {
        isHistoryEnabled = AppSettings.load().saveClipboardHistory
    }

    private func startRecordingOnLaunchIfNeeded() {
        guard !didHandleLaunchRecording else { return }
        didHandleLaunchRecording = true

        let settings = AppSettings.load()
        guard settings.startRecordingOnLaunch else { return }
        guard !viewModel.isRecording, !viewModel.isProcessing else { return }

        DispatchQueue.main.async {
            viewModel.startRecording()
        }
    }

    private func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stopRecording()
        } else {
            viewModel.startRecording()
        }
    }

    private var buttonSymbol: String {
        if viewModel.isProcessing {
            return "arrow.triangle.2.circlepath"
        }
        return viewModel.isRecording ? "stop.fill" : "mic.fill"
    }

    private var buttonFill: Color {
        if viewModel.isProcessing {
            return .indigo
        }
        return viewModel.isRecording ? .red : .teal
    }

    private var displayStatusText: String {
        if case .copied = viewModel.state {
            return "Tap to speak"
        }
        return viewModel.statusText
    }

    private var primaryStatusColor: Color {
        switch viewModel.state {
        case .failed:
            return .red
        default:
            return .primary
        }
    }
}

private struct ProcessingSpinnerIcon: View {
    @State private var isRotating = false

    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 58, weight: .semibold))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                .linear(duration: 0.9).repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = false
                DispatchQueue.main.async {
                    isRotating = true
                }
            }
    }
}

private struct IdleRippleView: View {
    var body: some View {
        ZStack {
            RippleRing(delay: 0)
            RippleRing(delay: 0.55)
        }
        .allowsHitTesting(false)
    }
}

private struct RippleRing: View {
    let delay: Double
    @State private var isExpanded = false

    var body: some View {
        Circle()
            .stroke(.teal.opacity(isExpanded ? 0 : 0.24), lineWidth: 2)
            .frame(width: 172, height: 172)
            .scaleEffect(isExpanded ? 1.42 : 1)
            .animation(
                .easeOut(duration: 1.8)
                    .delay(delay)
                    .repeatForever(autoreverses: false),
                value: isExpanded
            )
            .onAppear {
                isExpanded = false
                DispatchQueue.main.async {
                    isExpanded = true
                }
            }
    }
}

struct iOSHistoryView: View {
    @ObservedObject var viewModel: iOSVoiceReplyViewModel
    @State private var items: [ClipboardHistoryItem] = []
    @State private var isClearConfirmationVisible = false

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Copied replies will appear here.")
                )
            } else {
                ForEach(items) { item in
                    Button {
                        viewModel.copyReplyFromHistory(item.text)
                        loadItems()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(item.text)
                                    .lineLimit(2)
                                    .foregroundStyle(.primary)

                                Spacer(minLength: 12)

                                Text(timeString(for: item.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text("Tap to copy")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") {
                    isClearConfirmationVisible = true
                }
                .disabled(items.isEmpty)
            }
        }
        .alert("Clear history?", isPresented: $isClearConfirmationVisible) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearHistory()
            }
        } message: {
            Text("This will remove all copied replies from history.")
        }
        .onAppear(perform: loadItems)
        .refreshable {
            loadItems()
        }
    }

    private func loadItems() {
        items = ClipboardHistoryStore.shared.items()
    }

    private func clearHistory() {
        ClipboardHistoryStore.shared.clear()
        iOSQuickActionManager.shared.refresh()
        items = []
    }

    private func deleteItem(_ item: ClipboardHistoryItem) {
        ClipboardHistoryStore.shared.remove(id: item.id)
        iOSQuickActionManager.shared.refresh()
        loadItems()
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct iOSSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deepSeekKey = ""
    @State private var tone: ReplyTone = .casual
    @State private var outputVariant: OutputVariant = .britishEnglish
    @State private var speechLanguage: SpeechLanguage = .turkish
    @State private var contextPrompt = ""
    @State private var saveHistory = true
    @State private var startRecordingOnLaunch = false
    @State private var saveError: String?

    var body: some View {
        Form {
            Section("Providers") {
                SecureField("DeepSeek API Key", text: $deepSeekKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                LabeledContent("Transcription") {
                    Text("Apple Speech")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Reply") {
                Picker("Tone", selection: $tone) {
                    ForEach(ReplyTone.allCases) { tone in
                        Text(tone.displayName).tag(tone)
                    }
                }

                Picker("Output", selection: $outputVariant) {
                    ForEach(OutputVariant.allCases) { variant in
                        Text(variant.rawValue).tag(variant)
                    }
                }

                Picker("Speech", selection: $speechLanguage) {
                    ForEach(SpeechLanguage.allCases) { language in
                        Text(language.rawValue).tag(language)
                    }
                }
            }

            Section("Context") {
                TextEditor(text: $contextPrompt)
                    .frame(minHeight: 100)
                    .textInputAutocapitalization(.sentences)
            }

            Section("Privacy") {
                Toggle("Save history", isOn: $saveHistory)
            }

            Section {
                Toggle("Start listening on open", isOn: $startRecordingOnLaunch)
            } header: {
                Text("Startup")
            } footer: {
                Text("When enabled, opening Voice Replies starts recording right away.")
            }

            if let saveError {
                Section {
                    Text(saveError)
                        .foregroundStyle(.red)
                }
            }

            Section {
                HStack {
                    Spacer()
                    Text("Designed and developed by Huseyin Emanet")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let settings = AppSettings.load()
        deepSeekKey = KeychainStore.shared.read(account: KeychainAccount.deepSeekAPIKey) ?? ""
        tone = settings.tone
        outputVariant = settings.outputVariant
        speechLanguage = settings.speechLanguage
        contextPrompt = settings.contextPrompt
        saveHistory = settings.saveClipboardHistory
        startRecordingOnLaunch = settings.startRecordingOnLaunch
    }

    private func save() {
        do {
            let trimmedDeepSeekKey = deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedDeepSeekKey.isEmpty {
                try KeychainStore.shared.delete(account: KeychainAccount.deepSeekAPIKey)
            } else {
                try KeychainStore.shared.save(trimmedDeepSeekKey, account: KeychainAccount.deepSeekAPIKey)
            }

            let currentSettings = AppSettings.load()
            AppSettings(
                tone: tone,
                outputVariant: outputVariant,
                speechLanguage: speechLanguage,
                contextPrompt: contextPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
                shortcut: currentSettings.shortcut,
                saveClipboardHistory: saveHistory,
                startRecordingOnLaunch: startRecordingOnLaunch
            ).save()

            if !saveHistory {
                ClipboardHistoryStore.shared.clear()
            }
            iOSQuickActionManager.shared.refresh()
            NotificationCenter.default.post(name: .voiceReplySettingsDidChange, object: nil)

            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
