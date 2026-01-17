import SwiftUI

enum UserDefaultsKeys {
    static let selectedProfileId = "selectedProfileId"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedProfileId)
        let fallbackId = AccountProfile.loadProfiles().first?.id
        guard let profileId = selectedId ?? fallbackId,
              let profile = AccountProfile.profile(withId: profileId) else {
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
        } catch {
            lastError = error.localizedDescription
        }
    }
}

