import Foundation

/// Picks questions and tracks correct/incorrect stats (separate from unlock/lock state,
/// which lives in ScreenTimeManager/UnlockManager/DailyUsageStore).
final class QuizManager: ObservableObject {
    static let shared = QuizManager()

    @Published private(set) var currentQuestion: Question?

    private var recentIDs: [String] = []
    private let bank = QuestionBank.shared
    private let correctKey = "statsCorrect"
    private let incorrectKey = "statsIncorrect"

    func nextQuestion(categories: Set<QuestionCategory>) {
        let all = bank.questions(in: categories.isEmpty ? Set(QuestionCategory.allCases) : categories)
        let fresh = all.filter { !recentIDs.contains($0.id) }
        let pool = fresh.isEmpty ? all : fresh
        currentQuestion = pool.randomElement()
        if let q = currentQuestion {
            recentIDs.append(q.id)
            if recentIDs.count > 8 { recentIDs.removeFirst() }
        }
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
