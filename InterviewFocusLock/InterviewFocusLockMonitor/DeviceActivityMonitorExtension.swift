import DeviceActivity
import FamilyControls
import ManagedSettings

/// Runs in a separate process managed by iOS, independent of whether the main app
/// is running. When the unlock window (started in UnlockManager) ends, this re-applies
/// the shield to whatever apps/categories the user selected, re-locking them.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: ShieldConstants.storeName)

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        reapplyShield()
    }

    private func reapplyShield() {
        guard
            let data = AppGroup.userDefaults.data(forKey: ShieldConstants.selectionKey),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }
}
