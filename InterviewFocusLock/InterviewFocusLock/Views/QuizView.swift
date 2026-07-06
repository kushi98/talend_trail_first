import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quiz = QuizManager.shared

    @State private var selectedCategories: Set<QuestionCategory> = Set(QuestionCategory.allCases)
    @State private var hasStarted = false
    @State private var selectedOptionIndex: Int?
    @State private var isAnswered = false
    @State private var wasCorrect = false
    @State private var unlockMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if !hasStarted {
                    categoryPicker
                } else if let question = quiz.currentQuestion {
                    questionView(question)
                } else {
                    Text("No questions available.")
                }
            }
            .padding()
            .navigationTitle("Quiz to Unlock")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var categoryPicker: some View {
        VStack(spacing: 20) {
            Text("Pick topics to be quizzed on")
                .font(.headline)

            ForEach(QuestionCategory.allCases) { category in
                Toggle(category.displayName, isOn: Binding(
                    get: { selectedCategories.contains(category) },
                    set: { isOn in
                        if isOn { selectedCategories.insert(category) } else { selectedCategories.remove(category) }
                    }
                ))
            }
            .toggleStyle(.switch)

            Spacer()

            Button {
                quiz.nextQuestion(categories: selectedCategories)
                hasStarted = true
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedCategories.isEmpty)
        }
    }

    private func questionView(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.category.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(question.prompt)
                .font(.title3).bold()

            ForEach(question.options.indices, id: \.self) { index in
                optionButton(question, index)
            }

            if isAnswered {
                VStack(alignment: .leading, spacing: 8) {
                    Text(wasCorrect ? "Correct!" : "Not quite.")
                        .font(.headline)
                        .foregroundStyle(wasCorrect ? .green : .red)
                    Text(question.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let unlockMessage {
                        Text(unlockMessage)
                            .font(.subheadline).bold()
                    }
                }
                .padding(.top, 8)

                Spacer()

                Button {
                    if wasCorrect {
                        dismiss()
                    } else {
                        selectedOptionIndex = nil
                        isAnswered = false
                        unlockMessage = nil
                        quiz.nextQuestion(categories: selectedCategories)
                    }
                } label: {
                    Text(wasCorrect ? "Done" : "Try Another Question")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Spacer()
            }
        }
    }

    private func optionButton(_ question: Question, _ index: Int) -> some View {
        let isSelected = selectedOptionIndex == index
        let isCorrectOption = index == question.correctIndex

        return Button {
            guard !isAnswered else { return }
            selectedOptionIndex = index
            isAnswered = true
            wasCorrect = quiz.submitAnswer(index)
            if wasCorrect {
                switch UnlockManager.shared.grantUnlock() {
                case .granted(let remaining):
                    unlockMessage = "Unlocked for \(DailyUsageStore.shared.unlockMinutesPerCorrectAnswer) minutes. \(remaining) min left today."
                case .dailyCapReached:
                    unlockMessage = "Correct, but you've already used your \(DailyUsageStore.shared.dailyCapMinutes) daily minutes."
                case .schedulingFailed(let reason):
                    unlockMessage = "Correct, but couldn't start the unlock timer: \(reason)"
                }
            }
        } label: {
            HStack {
                Text(question.options[index])
                Spacer()
                if isAnswered && (isSelected || isCorrectOption) {
                    Image(systemName: isCorrectOption ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrectOption ? .green : .red)
                }
            }
            .padding()
            .background(backgroundColor(isSelected: isSelected, isCorrectOption: isCorrectOption), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
    }

    private func backgroundColor(isSelected: Bool, isCorrectOption: Bool) -> Color {
        guard isAnswered else { return Color.secondary.opacity(0.1) }
        if isCorrectOption { return Color.green.opacity(0.2) }
        if isSelected { return Color.red.opacity(0.2) }
        return Color.secondary.opacity(0.1)
    }
}
