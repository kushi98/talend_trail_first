import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = KeychainStore.loadAPIKey() ?? ""
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "aiModelID") ?? Self.models.first!
    @State private var savedMessage: String?

    private static let models = ["claude-sonnet-5", "claude-opus-4-8", "claude-haiku-4-5-20251001", "claude-fable-5"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Anthropic API Key") {
                    SecureField("sk-ant-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Stored only in this device's Keychain, never in source or in iCloud. Get a key at console.anthropic.com - you're billed directly by Anthropic for usage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Model") {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(Self.models, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section {
                    Button("Clear Saved Key", role: .destructive) {
                        KeychainStore.deleteAPIKey()
                        apiKey = ""
                        savedMessage = "Key cleared. Quiz will use the offline question bank until a new key is saved."
                    }
                }

                if let savedMessage {
                    Section {
                        Text(savedMessage).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("AI Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeychainStore.saveAPIKey(apiKey)
                        UserDefaults.standard.set(selectedModel, forKey: "aiModelID")
                        savedMessage = "Saved."
                    }
                }
            }
        }
    }
}
