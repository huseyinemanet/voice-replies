import Foundation

func validate(response: URLResponse, data: Data, serviceName: String) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw VoiceReplyError.invalidServerResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
        throw VoiceReplyError.requestFailed(errorMessage(
            serviceName: serviceName,
            statusCode: httpResponse.statusCode
        ))
    }
}

private func errorMessage(serviceName: String, statusCode: Int) -> String {
    switch statusCode {
    case 401, 403:
        return "\(serviceName) rejected the API key. Check Settings and try again."
    case 408:
        return "\(serviceName) timed out. Try again in a moment."
    case 413:
        return "The recording is too large for \(serviceName). Try a shorter message."
    case 429:
        return "\(serviceName) rate limit reached. Wait a bit and try again."
    case 500..<600:
        return "\(serviceName) is having a server issue. Try again in a moment."
    default:
        return "\(serviceName) request failed with status \(statusCode)."
    }
}
