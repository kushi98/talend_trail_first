import Foundation
import DeviceActivity

enum UnlockResult {
    case granted(remainingMinutesToday: Int)
    case dailyCapReached
    case schedulingFailed(String)
}

/// Grants a fixed-length unlock window after a correct answer by removing the shield
/// and scheduling a DeviceActivityMonitor to re-apply it when the window ends - this
/// keeps the re-lock reliable even if the app isn't running (iOS runs the extension).
@MainActor
final class UnlockManager {
    static let shared = UnlockManager()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("interviewFocusUnlock")
    private let usage = DailyUsageStore.shared

    func grantUnlock() -> UnlockResult {
        guard usage.canEarnAnotherUnlock else {
            return .dailyCapReached
        }

        let now = Date()
        guard let end = Calendar.current.date(byAdding: .minute, value: usage.unlockMinutesPerCorrectAnswer, to: now) else {
            return .schedulingFailed("Could not compute unlock end time")
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: end),
            repeats: false
        )

        center.stopMonitoring([activityName])
        do {
            try center.startMonitoring(activityName, during: schedule)
        } catch {
            return .schedulingFailed(error.localizedDescription)
        }

        ScreenTimeManager.shared.removeShield()
        usage.recordUnlockUsage()
        UnlockWindowStore.endsAt = end
        return .granted(remainingMinutesToday: usage.remainingMinutesToday)
    }
}
