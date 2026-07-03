import SwiftUI
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

struct ContentView: View {
    @StateObject private var viewModel = iOSVoiceReplyViewModel()
    @State private var isPressing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Button {
                } label: {
                    ZStack {
                        Circle()
                            .fill(buttonFill)
                            .frame(width: 172, height: 172)
                            .shadow(color: .black.opacity(0.16), radius: 20, y: 10)

                        Image(systemName: buttonSymbol)
                            .font(.system(size: 58, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(isPressing || viewModel.isRecording ? 0.96 : 1)
                .animation(.snappy(duration: 0.16), value: isPressing)
                .animation(.snappy(duration: 0.16), value: viewModel.isRecording)
                .simultaneousGesture(pressGesture)
                .disabled(viewModel.isProcessing)

                VStack(spacing: 8) {
                    Text(viewModel.statusText)
                        .font(.headline)
                        .foregroundStyle(primaryStatusColor)

                    Text("Hold to record. Release to translate.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                NavigationLink {
                    iOSSettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPressing else { return }
                isPressing = true
                viewModel.startRecording()
            }
            .onEnded { _ in
                isPressing = false
                viewModel.stopRecording()
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

    private var primaryStatusColor: Color {
        switch viewModel.state {
        case .failed:
            return .red
        case .copied:
            return .green
        default:
            return .primary
        }
    }
}

struct iOSSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deepSeekKey = ""
    @State private var transcriptionKey = ""
    @State private var tone: ReplyTone = .casual
    @State private var outputVariant: OutputVariant = .britishEnglish
    @State private var speechLanguage: SpeechLanguage = .turkish
    @State private var contextPrompt = ""
    @State private var saveHistory = true
    @State private var saveError: String?

    var body: some View {
        Form {
            Section("Providers") {
                SecureField("DeepSeek API Key", text: $deepSeekKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Transcription API Key", text: $transcriptionKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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

            if let saveError {
                Section {
                    Text(saveError)
                        .foregroundStyle(.red)
                }
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
        transcriptionKey = KeychainStore.shared.read(account: KeychainAccount.openAIAPIKey) ?? ""
        tone = settings.tone
        outputVariant = settings.outputVariant
        speechLanguage = settings.speechLanguage
        contextPrompt = settings.contextPrompt
        saveHistory = settings.saveClipboardHistory
    }

    private func save() {
        do {
            let trimmedDeepSeekKey = deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTranscriptionKey = transcriptionKey.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedDeepSeekKey.isEmpty {
                try KeychainStore.shared.delete(account: KeychainAccount.deepSeekAPIKey)
            } else {
                try KeychainStore.shared.save(trimmedDeepSeekKey, account: KeychainAccount.deepSeekAPIKey)
            }

            if trimmedTranscriptionKey.isEmpty {
                try KeychainStore.shared.delete(account: KeychainAccount.openAIAPIKey)
            } else {
                try KeychainStore.shared.save(trimmedTranscriptionKey, account: KeychainAccount.openAIAPIKey)
            }

            AppSettings(
                tone: tone,
                outputVariant: outputVariant,
                speechLanguage: speechLanguage,
                contextPrompt: contextPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
                saveClipboardHistory: saveHistory
            ).save()

            if !saveHistory {
                ClipboardHistoryStore.shared.clear()
            }

            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
