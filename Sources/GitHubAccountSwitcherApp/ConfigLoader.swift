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
        let urls = candidateConfigURLs()
        for url in urls {
            let exists = FileManager.default.fileExists(atPath: url.path)
            // #region agent log
            DebugLogger.log(
                hypothesisId: "A",
                location: "ConfigLoader.swift:27",
                message: "Config file existence check",
                data: [
                    "path": url.path,
                    "exists": exists ? "true" : "false",
                ]
            )
            // #endregion
            guard exists else { continue }

            // #region agent log
            DebugLogger.log(
                hypothesisId: "A",
                location: "ConfigLoader.swift:37",
                message: "Config path selected",
                data: ["path": url.path]
            )
            // #endregion

            return loadProfiles(from: url)
        }

        return nil
    }

    private static func loadProfiles(from url: URL) -> [AccountProfile]? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            if let list = try? decoder.decode([ConfigProfile].self, from: data) {
                // #region agent log
                DebugLogger.log(
                    hypothesisId: "B",
                    location: "ConfigLoader.swift:57",
                    message: "Decoded config as array",
                    data: ["count": String(list.count)]
                )
                // #endregion
                return list.map(AccountProfile.init)
            }

            let wrapped = try decoder.decode(ConfigFile.self, from: data)
            // #region agent log
            DebugLogger.log(
                hypothesisId: "B",
                location: "ConfigLoader.swift:68",
                message: "Decoded config as wrapped object",
                data: ["count": String(wrapped.profiles.count)]
            )
            // #endregion
            return wrapped.profiles.map(AccountProfile.init)
        } catch {
            // #region agent log
            DebugLogger.log(
                hypothesisId: "B",
                location: "ConfigLoader.swift:75",
                message: "Failed to decode config",
                data: ["error": error.localizedDescription]
            )
            // #endregion
            return nil
        }
    }

    private static func candidateConfigURLs() -> [URL] {
        var urls: [URL] = []
        if let appSupportURL = configURL() {
            urls.append(appSupportURL)
        }
        if let envURL = envConfigURL() {
            urls.append(envURL)
        }
        if let cwdURL = cwdConfigURL() {
            urls.append(cwdURL)
        }
        return urls
    }

    private static func configURL() -> URL? {
        guard
            let base = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            return nil
        }

        return
            base
            .appendingPathComponent("GitHubAccountSwitcher", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    private static func envConfigURL() -> URL? {
        guard let value = ProcessInfo.processInfo.environment["GITHUB_ACCOUNT_SWITCHER_CONFIG"],
            !value.isEmpty
        else {
            return nil
        }
        return URL(fileURLWithPath: value)
    }

    private static func cwdConfigURL() -> URL? {
        let cwd = FileManager.default.currentDirectoryPath
        guard !cwd.isEmpty else { return nil }
        return URL(fileURLWithPath: cwd).appendingPathComponent("config.json")
    }
}

extension AccountProfile {
    fileprivate init(_ config: ConfigLoader.ConfigProfile) {
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
