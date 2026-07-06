import Foundation

/// Picks questions - AI-generated via Claude by default, falling back silently to the
/// bundled seed bank if there's no API key, no network, or the API call fails for any
/// reason - and tracks correct/incorrect stats (separate from unlock/lock state, which
/// lives in ScreenTimeManager/UnlockManager/DailyUsageStore).
@MainActor
final class QuizManager: ObservableObject {
    static let shared = QuizManager()

    @Published private(set) var currentQuestion: Question?
    @Published private(set) var isLoading = false
    @Published private(set) var isUsingOfflineFallback = false

    private var recentPrompts: [String] = []
    private let bank = QuestionBank.shared
    private let correctKey = "statsCorrect"
    private let incorrectKey = "statsIncorrect"

    func nextQuestion(categories: Set<QuestionCategory>) async {
        isLoading = true
        isUsingOfflineFallback = false
        defer { isLoading = false }

        let categorySet = categories.isEmpty ? Set(QuestionCategory.allCases) : categories
        let category = categorySet.randomElement() ?? .generalSWE
        let difficulty = ["mid", "senior"].randomElement() ?? "senior"

        do {
            let question = try await AIQuestionService.shared.generateQuestion(
                category: category,
                difficulty: difficulty,
                avoiding: recentPrompts
            )
            currentQuestion = question
            trackRecent(question.prompt)
        } catch {
            isUsingOfflineFallback = true
            currentQuestion = fallbackQuestion(categories: categorySet)
        }
    }

    private func fallbackQuestion(categories: Set<QuestionCategory>) -> Question? {
        let all = bank.questions(in: categories)
        let fresh = all.filter { !recentPrompts.contains($0.prompt) }
        let pool = fresh.isEmpty ? all : fresh
        let question = pool.randomElement()
        if let question { trackRecent(question.prompt) }
        return question
    }

    private func trackRecent(_ prompt: String) {
        recentPrompts.append(prompt)
        if recentPrompts.count > 8 { recentPrompts.removeFirst() }
    }

    @discardableResult
    func submitAnswer(_ index: Int) -> Bool {
        guard let q = currentQuestion else { return false }
        let correct = index == q.correctIndex
        let defaults = AppGroup.userDefaults
        let key = correct ? correctKey : incorrectKey
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
        return correct
    }

    var totalCorrect: Int { AppGroup.userDefaults.integer(forKey: correctKey) }
    var totalIncorrect: Int { AppGroup.userDefaults.integer(forKey: incorrectKey) }
    var accuracyPercent: Int {
        let total = totalCorrect + totalIncorrect
        guard total > 0 else { return 0 }
        return Int((Double(totalCorrect) / Double(total) * 100).rounded())
    }
}
