import Foundation

enum AIQuestionError: Error {
    case noAPIKey
    case network(Error)
    case badResponse(Int)
    case decodingFailed
}

/// Calls the Claude API to generate a fresh multiple-choice interview question on demand.
/// Requires the user's own Anthropic API key (set in Settings, stored in Keychain) - this
/// app never ships or embeds a key of its own.
final class AIQuestionService {
    static let shared = AIQuestionService()

    private static let defaultModel = "claude-sonnet-5"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private var model: String {
        UserDefaults.standard.string(forKey: "aiModelID") ?? Self.defaultModel
    }

    func generateQuestion(
        category: QuestionCategory,
        difficulty: String,
        avoiding recentPrompts: [String]
    ) async throws -> Question {
        guard let apiKey = KeychainStore.loadAPIKey(), !apiKey.isEmpty else {
            throw AIQuestionError.noAPIKey
        }

        let avoidClause = recentPrompts.isEmpty
            ? ""
            : "\nDo not repeat or closely resemble any of these already-asked questions:\n- " + recentPrompts.joined(separator: "\n- ")

        let userPrompt = """
        Generate one multiple-choice interview question for a candidate with 6 years of experience, \
        on the topic "\(category.displayName)", at \(difficulty) difficulty.\(avoidClause)

        Respond with ONLY raw JSON, no markdown fences, no commentary, matching exactly this shape:
        {"prompt": "...", "options": ["...", "...", "...", "..."], "correctIndex": 0, "explanation": "..."}

        Requirements: exactly 4 options, correctIndex is the 0-based index of the correct option, \
        and the explanation should justify the correct answer in 1-2 sentences.
        """

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "max_tokens": 600,
            "messages": [["role": "user", "content": userPrompt]]
        ])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIQuestionError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIQuestionError.decodingFailed
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AIQuestionError.badResponse(http.statusCode)
        }

        struct MessagesResponse: Decodable {
            struct ContentBlock: Decodable { let text: String? }
            let content: [ContentBlock]
        }
        struct GeneratedQuestion: Decodable {
            let prompt: String
            let options: [String]
            let correctIndex: Int
            let explanation: String
        }

        guard
            let decoded = try? JSONDecoder().decode(MessagesResponse.self, from: data),
            let text = decoded.content.first(where: { $0.text != nil })?.text,
            let jsonText = Self.extractJSONObject(from: text),
            let jsonData = jsonText.data(using: .utf8),
            let generated = try? JSONDecoder().decode(GeneratedQuestion.self, from: jsonData),
            generated.options.count == 4,
            (0...3).contains(generated.correctIndex)
        else {
            throw AIQuestionError.decodingFailed
        }

        return Question(
            id: UUID().uuidString,
            category: category,
            difficulty: difficulty,
            prompt: generated.prompt,
            options: generated.options,
            correctIndex: generated.correctIndex,
            explanation: generated.explanation
        )
    }

    /// Claude sometimes wraps JSON in prose or fences despite instructions; take the
    /// outermost {...} span rather than trusting the whole response body is bare JSON.
    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start < end else {
            return nil
        }
        return String(text[start...end])
    }
}
