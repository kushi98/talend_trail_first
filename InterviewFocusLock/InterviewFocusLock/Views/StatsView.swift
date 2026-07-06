import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    private let quiz = QuizManager.shared
    private let usage = DailyUsageStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    LabeledContent("Unlock minutes used", value: "\(usage.usedMinutesToday) / \(usage.dailyCapMinutes)")
                    LabeledContent("Minutes remaining", value: "\(usage.remainingMinutesToday)")
                }
                Section("All-Time Quiz Stats") {
                    LabeledContent("Correct answers", value: "\(quiz.totalCorrect)")
                    LabeledContent("Incorrect answers", value: "\(quiz.totalIncorrect)")
                    LabeledContent("Accuracy", value: "\(quiz.accuracyPercent)%")
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
