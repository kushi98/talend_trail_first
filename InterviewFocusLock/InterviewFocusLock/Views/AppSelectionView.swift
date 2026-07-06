import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var draftSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    let isInitialSetup: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "apps.iphone")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text(isInitialSetup ? "Choose apps to lock" : "Edit locked apps")
                .font(.title2).bold()

            Text("Pick the apps or categories (social media, games, etc.) you want blocked while you're prepping. You'll only get in by answering an interview question correctly.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if draftSelection.applicationTokens.count + draftSelection.categoryTokens.count > 0 {
                Text("\(draftSelection.applicationTokens.count) app(s) and \(draftSelection.categoryTokens.count) categorie(s) selected")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isPickerPresented = true
            } label: {
                Text("Choose Apps & Categories")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.horizontal)

            Button {
                screenTime.saveSelection(draftSelection)
            } label: {
                Text("Lock These Apps")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .disabled(draftSelection.applicationTokens.isEmpty && draftSelection.categoryTokens.isEmpty)

            Spacer().frame(height: 12)
        }
        .padding()
        .onAppear { draftSelection = screenTime.selection }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $draftSelection)
    }
}
