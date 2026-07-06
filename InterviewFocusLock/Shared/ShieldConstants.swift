import Foundation
import ManagedSettings

/// Constants shared between the main app and the DeviceActivityMonitor extension,
/// since Swift types defined in one target's sources aren't visible from the other.
enum ShieldConstants {
    static let storeName = ManagedSettingsStore.Name("InterviewFocusLockShield")
    static let selectionKey = "blockedSelectionData"
}
