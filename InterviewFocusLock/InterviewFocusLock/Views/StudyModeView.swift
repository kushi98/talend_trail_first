import SwiftUI

/// Free browsing of the full question bank with answers shown - for prep,
/// completely separate from the quiz-to-unlock flow (never grants unlock time).
struct StudyModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: QuestionCategory?

    private var groupedQuestions: [QuestionCategory: [Question]] {
        Dictionary(grouping: QuestionBank.shared.questions, by: \.category)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(QuestionCategory.allCases) { category in
                    Section(category.displayName) {
                        ForEach(groupedQuestions[category] ?? []) { question in
                            DisclosureGroup(question.prompt) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(question.options.indices, id: \.self) { index in
                                        HStack(alignment: .top) {
                                            Image(systemName: index == question.correctIndex ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(index == question.correctIndex ? .green : .secondary)
                                            Text(question.options[index])
                                                .font(.subheadline)
                                        }
                                    }
                                    Text(question.explanation)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 4)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Study Mode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
