import Foundation

final class QuestionBank {
    static let shared = QuestionBank()

    let questions: [Question]

    private init() {
        guard
            let url = Bundle.main.url(forResource: "Questions", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([Question].self, from: data)
        else {
            assertionFailure("Questions.json is missing or malformed")
            self.questions = []
            return
        }
        self.questions = decoded
    }

    func questions(in categories: Set<QuestionCategory>) -> [Question] {
        questions.filter { categories.contains($0.category) }
    }
}
