import Foundation

func validate(response: URLResponse, data: Data, serviceName: String) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw VoiceReplyError.invalidServerResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
        let body = String(data: data, encoding: .utf8) ?? "No response body"
        throw VoiceReplyError.requestFailed("\(serviceName) request failed with status \(httpResponse.statusCode): \(body)")
    }
}
