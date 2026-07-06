import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var isRequesting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Interview Focus Lock")
                .font(.title).bold()

            Text("Pick the apps that distract you. They'll stay locked until you answer an interview question correctly - each correct answer earns 10 minutes of access, up to 60 minutes total per day.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Text("This requires Screen Time permission (Apple's Family Controls framework) so the app can lock/unlock other apps on this device.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                Task {
                    isRequesting = true
                    await screenTime.requestAuthorization()
                    isRequesting = false
                    if screenTime.authorizationStatus != .approved {
                        errorMessage = "Screen Time access wasn't granted. Enable it to continue - you can also grant it later in Settings > Screen Time."
                    }
                }
            } label: {
                if isRequesting {
                    ProgressView()
                } else {
                    Text("Enable Screen Time Access")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .disabled(isRequesting)

            Spacer().frame(height: 12)
        }
        .padding()
    }
}
