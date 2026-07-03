import Foundation

enum NetworkRetry {
    static func data(for request: URLRequest, maxAttempts: Int = 3) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if shouldRetry(response: response), attempt < maxAttempts {
                    try await pause(beforeAttempt: attempt + 1)
                    continue
                }

                return (data, response)
            } catch let error as URLError where shouldRetry(error: error) && attempt < maxAttempts {
                lastError = error
                try await pause(beforeAttempt: attempt + 1)
            } catch {
                throw error
            }
        }

        throw lastError ?? VoiceReplyError.requestFailed("The request failed after retrying.")
    }

    private static func shouldRetry(response: URLResponse) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 408
            || httpResponse.statusCode == 429
            || (500...599).contains(httpResponse.statusCode)
    }

    private static func shouldRetry(error: URLError) -> Bool {
        switch error.code {
        case .timedOut,
             .networkConnectionLost,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private static func pause(beforeAttempt attempt: Int) async throws {
        let delay = UInt64(attempt) * 700_000_000
        try await Task.sleep(nanoseconds: delay)
    }
}
