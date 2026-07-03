import Foundation

final class TranscriptionService {
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    func transcribeTurkishAudio(fileURL: URL, apiKey: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpBody = try multipartBody(
            boundary: boundary,
            fields: [
                "model": "whisper-1",
                "language": "tr",
                "prompt": "Turkish workplace voice reply. It may include English product names and technical terms such as Slack, Framer, GitHub, Codex, OpenAI, DeepSeek, API, design, developer, release, and bug.",
                "response_format": "json"
            ],
            fileURL: fileURL,
            fileFieldName: "file",
            mimeType: "audio/m4a"
        )

        let (data, response) = try await NetworkRetry.data(for: request)
        try validate(response: response, data: data, serviceName: "OpenAI transcription")

        let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        let transcript = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            throw VoiceReplyError.emptyTranscription
        }

        return transcript
    }

    private func multipartBody(
        boundary: String,
        fields: [String: String],
        fileURL: URL,
        fileFieldName: String,
        mimeType: String
    ) throws -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for (name, value) in fields {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak + lineBreak)")
            body.append("\(value)\(lineBreak)")
        }

        let fileData = try Data(contentsOf: fileURL)
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileURL.lastPathComponent)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak + lineBreak)")
        body.append(fileData)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")

        return body
    }
}

private struct TranscriptionResponse: Decodable {
    let text: String
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
