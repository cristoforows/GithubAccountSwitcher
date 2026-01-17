import Foundation

struct AccountProfile: Identifiable, Equatable {
    let id: String
    let displayName: String
    let gitUserName: String
    let gitUserEmail: String
    let sshHostAliases: [String]
    let sshIdentityFilePath: String
}

extension AccountProfile {
    // Update these values to match your work/personal identity and SSH keys.
    static let defaultProfiles: [AccountProfile] = [
        AccountProfile(
            id: "work",
            displayName: "GitHub Work",
            gitUserName: "Work Name",
            gitUserEmail: "work@example.com",
            sshHostAliases: ["github-work"],
            sshIdentityFilePath: "~/.ssh/id_rsa_work"
        ),
        AccountProfile(
            id: "personal",
            displayName: "GitHub Personal",
            gitUserName: "Personal Name",
            gitUserEmail: "personal@example.com",
            sshHostAliases: ["github-personal"],
            sshIdentityFilePath: "~/.ssh/id_rsa_personal"
        )
    ]

    static func profile(withId id: String) -> AccountProfile? {
        loadProfiles().first { $0.id == id }
    }

    static func loadProfiles() -> [AccountProfile] {
        guard let configProfiles = ConfigLoader.loadProfiles(), !configProfiles.isEmpty else {
            return defaultProfiles
        }
        return configProfiles
    }
}

