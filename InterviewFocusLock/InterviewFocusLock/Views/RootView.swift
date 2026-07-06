import SwiftUI
import FamilyControls

struct RootView: View {
    @StateObject private var screenTime = ScreenTimeManager.shared

    var body: some View {
        Group {
            if screenTime.authorizationStatus != .approved {
                OnboardingView()
            } else if !screenTime.hasAppsSelected {
                AppSelectionView(isInitialSetup: true)
            } else {
                HomeView()
            }
        }
        .environmentObject(screenTime)
    }
}
