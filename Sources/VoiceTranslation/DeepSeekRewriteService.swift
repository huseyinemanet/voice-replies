import Foundation

final class DeepSeekRewriteService {
    private let endpoint = URL(string: "https://api.deepseek.com/chat/completions")!

    func rewrite(
        turkishText: String,
        tone: ReplyTone,
        outputVariant: OutputVariant,
        contextPrompt: String,
        apiKey: String
    ) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let systemPrompt = """
        Rewrite Turkish Slack replies as natural workplace English.
        Sound like two people chatting at work, not a formal corporate message.
        Preserve intent, nuance, and directness. Do not add information.
        Follow the requested English variant exactly.
        If the input is unclear, keep the reply short and do not guess details.
        Never use em dashes or en dashes. Return only the final message.
        """

        let userPrompt = """
        Tone: \(toneInstruction(for: tone))
        Variant: \(outputVariant.instruction)
        Optional user context: \(contextInstruction(from: contextPrompt))
        \(turkishText)
        """

        let payload = ChatCompletionRequest(
            model: "deepseek-v4-flash",
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: temperature(for: tone),
            maxTokens: 220,
            thinking: .init(type: "disabled")
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data, serviceName: "DeepSeek")

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let message = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else {
            throw VoiceReplyError.emptyModelResponse
        }

        return cleanRewriteOutput(message)
    }

    private func temperature(for tone: ReplyTone) -> Double {
        switch tone {
        case .casual:
            return 0.7
        case .neutral:
            return 0.45
        case .polished:
            return 0.35
        }
    }

    private func toneInstruction(for tone: ReplyTone) -> String {
        switch tone {
        case .casual:
            return "casual, warm, everyday Slack chat"
        case .neutral:
            return "natural, clear, conversational"
        case .polished:
            return "polished but still human and conversational"
        }
    }

    private func contextInstruction(from contextPrompt: String) -> String {
        let trimmedPrompt = contextPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedPrompt.isEmpty {
            return "none"
        }

        return String(trimmedPrompt.prefix(600))
    }

    private func cleanRewriteOutput(_ text: String) -> String {
        text
            .replacingOccurrences(of: "—", with: ",")
            .replacingOccurrences(of: "–", with: ",")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int
    let thinking: Thinking

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case thinking
    }

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct Thinking: Encodable {
        let type: String
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}
