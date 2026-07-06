import Foundation

/// Tracks how many "unlock minutes" have been spent today, capped at `dailyCapMinutes`.
/// Shared between the main app (to decide whether a correct answer earns unlock time)
/// and read-only by the extension for diagnostics.
final class DailyUsageStore {
    static let shared = DailyUsageStore()

    let dailyCapMinutes = 60
    let unlockMinutesPerCorrectAnswer = 10

    private let usedMinutesKey = "usedMinutesToday"
    private let usedDateKey = "usedMinutesDate"
    private var defaults: UserDefaults { AppGroup.userDefaults }

    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = defaults.object(forKey: usedDateKey) as? Date ?? .distantPast
        if !Calendar.current.isDate(lastDate, inSameDayAs: today) {
            defaults.set(0, forKey: usedMinutesKey)
            defaults.set(today, forKey: usedDateKey)
        }
    }

    var usedMinutesToday: Int {
        resetIfNewDay()
        return defaults.integer(forKey: usedMinutesKey)
    }

    var remainingMinutesToday: Int {
        max(0, dailyCapMinutes - usedMinutesToday)
    }

    var canEarnAnotherUnlock: Bool {
        remainingMinutesToday >= unlockMinutesPerCorrectAnswer
    }

    func recordUnlockUsage() {
        resetIfNewDay()
        defaults.set(usedMinutesToday + unlockMinutesPerCorrectAnswer, forKey: usedMinutesKey)
    }
}
