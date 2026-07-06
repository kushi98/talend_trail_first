import Foundation

/// Persists when the current unlock window ends so the UI can show a countdown
/// even across app restarts (the actual re-lock is enforced by the extension).
enum UnlockWindowStore {
    private static let endsAtKey = "unlockEndsAt"

    static var endsAt: Date? {
        get { AppGroup.userDefaults.object(forKey: endsAtKey) as? Date }
        set { AppGroup.userDefaults.set(newValue, forKey: endsAtKey) }
    }

    static var isActive: Bool {
        guard let endsAt else { return false }
        return endsAt > Date()
    }

    static var remainingSeconds: Int {
        guard let endsAt else { return 0 }
        return max(0, Int(endsAt.timeIntervalSinceNow))
    }
}
