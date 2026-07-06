import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

/// Owns Screen Time authorization and the shield (lock) state for the apps/categories
/// the user picked to block. The same shield store name is used by the
/// DeviceActivityMonitor extension so it can re-apply the lock after an unlock window ends.
@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var selection = FamilyActivitySelection()
    @Published private(set) var isCurrentlyShielded = true

    private let store = ManagedSettingsStore(named: ShieldConstants.storeName)

    private init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        loadSelection()
    }

    var hasAppsSelected: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            print("Screen Time authorization failed: \(error)")
        }
    }

    /// Persists the chosen apps/categories to block and immediately locks them.
    func saveSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        if let data = try? JSONEncoder().encode(newSelection) {
            AppGroup.userDefaults.set(data, forKey: ShieldConstants.selectionKey)
        }
        applyShield()
    }

    private func loadSelection() {
        if let data = AppGroup.userDefaults.data(forKey: ShieldConstants.selectionKey),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        }
    }

    func applyShield() {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        isCurrentlyShielded = true
    }

    func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        isCurrentlyShielded = false
    }
}
