import Foundation

enum ConfigLoader {
    struct ConfigProfile: Codable {
        let id: String
        let displayName: String
        let gitUserName: String
        let gitUserEmail: String
        let sshHostAliases: [String]
        let sshIdentityFilePath: String
    }

    struct ConfigFile: Codable {
        let profiles: [ConfigProfile]
    }

    static func loadProfiles() -> [AccountProfile]? {
        guard let url = configURL(), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            if let list = try? decoder.decode([ConfigProfile].self, from: data) {
                return list.map(AccountProfile.init)
            }

            let wrapped = try decoder.decode(ConfigFile.self, from: data)
            return wrapped.profiles.map(AccountProfile.init)
        } catch {
            return nil
        }
    }

    static func configURL() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        return base
            .appendingPathComponent("GitHubAccountSwitcher", isDirectory: true)
            .appendingPathComponent("config.json")
    }
}

private extension AccountProfile {
    init(_ config: ConfigLoader.ConfigProfile) {
        self.init(
            id: config.id,
            displayName: config.displayName,
            gitUserName: config.gitUserName,
            gitUserEmail: config.gitUserEmail,
            sshHostAliases: config.sshHostAliases,
            sshIdentityFilePath: config.sshIdentityFilePath
        )
    }
}

