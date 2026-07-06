import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var isQuizPresented = false
    @State private var isStudyPresented = false
    @State private var isStatsPresented = false
    @State private var isEditAppsPresented = false
    @State private var isSettingsPresented = false
    @State private var now = Date()

    private let usage = DailyUsageStore.shared
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isUnlocked: Bool { UnlockWindowStore.isActive }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusCard

                VStack(spacing: 12) {
                    Text("Today's unlock time used")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(usage.usedMinutesToday), total: Double(usage.dailyCapMinutes))
                        .tint(.orange)
                    Text("\(usage.usedMinutesToday) / \(usage.dailyCapMinutes) min today")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    isQuizPresented = true
                } label: {
                    Label("Answer a Question to Unlock", systemImage: "key.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!usage.canEarnAnotherUnlock)

                if !usage.canEarnAnotherUnlock {
                    Text("You've used all \(usage.dailyCapMinutes) minutes today. Locked apps stay locked until tomorrow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if KeychainStore.loadAPIKey() == nil {
                    Text("No Anthropic API key set - tap the gear icon to add one for AI-generated questions. The built-in question bank will be used until then.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    isStudyPresented = true
                } label: {
                    Label("Study Mode (no unlock needed)", systemImage: "book.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                HStack(spacing: 12) {
                    Button {
                        isStatsPresented = true
                    } label: {
                        Label("Stats", systemImage: "chart.bar.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        isEditAppsPresented = true
                    } label: {
                        Label("Edit Apps", systemImage: "apps.iphone")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Interview Focus Lock")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .onReceive(timer) { now = $0 }
            .sheet(isPresented: $isQuizPresented) { QuizView() }
            .sheet(isPresented: $isStudyPresented) { StudyModeView() }
            .sheet(isPresented: $isStatsPresented) { StatsView() }
            .sheet(isPresented: $isEditAppsPresented) { AppSelectionView(isInitialSetup: false) }
            .sheet(isPresented: $isSettingsPresented) { SettingsView() }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 8) {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(isUnlocked ? .green : .red)

            if isUnlocked {
                Text("Unlocked")
                    .font(.title3).bold()
                Text(timeString(from: UnlockWindowStore.remainingSeconds))
                    .font(.system(.title, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text("Locked")
                    .font(.title3).bold()
                Text("Answer a question correctly to unlock for \(usage.unlockMinutesPerCorrectAnswer) minutes")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func timeString(from seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
