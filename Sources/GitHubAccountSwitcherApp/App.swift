import SwiftUI

enum UserDefaultsKeys {
    static let selectedProfileId = "selectedProfileId"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedProfileId)
        let fallbackId = AccountProfile.loadProfiles().first?.id
        // #region agent log
        DebugLogger.log(
            hypothesisId: "E",
            location: "App.swift:10",
            message: "App launch profile selection",
            data: [
                "selectedId": selectedId ?? "nil",
                "fallbackId": fallbackId ?? "nil"
            ]
        )
        // #endregion
        guard let profileId = selectedId ?? fallbackId,
              let profile = AccountProfile.profile(withId: profileId) else {
            // #region agent log
            DebugLogger.log(
                hypothesisId: "E",
                location: "App.swift:19",
                message: "Profile not found at launch",
                data: [
                    "resolvedProfileId": (selectedId ?? fallbackId) ?? "nil"
                ]
            )
            // #endregion
            return
        }

        try? AccountSwitcher.switchTo(profile)
    }
}

@main
struct GitHubAccountSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(UserDefaultsKeys.selectedProfileId) private var selectedProfileId: String = AccountProfile.loadProfiles().first?.id ?? "work"

    @State private var lastError: String?

    var body: some Scene {
        let profiles = AccountProfile.loadProfiles()
        MenuBarExtra("GitHub", systemImage: "person.crop.circle") {
            ForEach(profiles) { profile in
                Button {
                    switchToProfile(profile)
                } label: {
                    HStack {
                        if profile.id == selectedProfileId {
                            Image(systemName: "checkmark")
                        }
                        Text(profile.displayName)
                    }
                }
            }

            if let lastError {
                Divider()
                Text("Last error: \(lastError)")
                    .font(.footnote)
            }

            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func switchToProfile(_ profile: AccountProfile) {
        do {
            try AccountSwitcher.switchTo(profile)
            selectedProfileId = profile.id
            lastError = nil
            // #region agent log
            DebugLogger.log(
                hypothesisId: "E",
                location: "App.swift:63",
                message: "Switch completed",
                data: [
                    "profileId": profile.id
                ],
                runId: "run2"
            )
            // #endregion
        } catch {
            lastError = error.localizedDescription
            // #region agent log
            DebugLogger.log(
                hypothesisId: "E",
                location: "App.swift:70",
                message: "Switch failed",
                data: [
                    "error": error.localizedDescription
                ],
                runId: "run2"
            )
            // #endregion
        }
    }
}

