import Foundation

/// Shared storage identifier used by both the main app and the DeviceActivityMonitor
/// extension so they can read/write the same blocked-app selection and usage data.
///
/// IMPORTANT: change this to an App Group ID you own (must start with "group.")
/// and match it in both entitlements files and in project.yml if you rename it.
enum AppGroup {
    static let identifier = "group.com.kushal.interviewfocuslock"

    static var userDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: identifier) else {
            fatalError("App Group '\(identifier)' is not configured. Check entitlements on both targets.")
        }
        return defaults
    }
}
