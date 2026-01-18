import Foundation

enum AccountSwitcherError: LocalizedError {
    case commandFailed(command: String, output: String)
    case sshConfigUpdateFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let output):
            return "Command failed: \(command). \(output)"
        case .sshConfigUpdateFailed(let message):
            return "SSH config update failed: \(message)"
        }
    }
}

enum AccountSwitcher {
    static func switchTo(_ profile: AccountProfile) throws {
        // #region agent log
        DebugLogger.log(
            hypothesisId: "C",
            location: "AccountSwitcher.swift:17",
            message: "Switch start",
            data: [
                "profileId": profile.id,
                "gitUserEmail": profile.gitUserEmail,
                "sshIdentityPath": profile.sshIdentityFilePath,
            ]
        )
        // #endregion
        try setGitGlobal(key: "user.name", value: profile.gitUserName)
        try setGitGlobal(key: "user.email", value: profile.gitUserEmail)

        do {
            try SSHConfigEditor.updateIdentityFile(
                forHosts: profile.sshHostAliases,
                identityFilePath: profile.sshIdentityFilePath
            )
        } catch {
            throw AccountSwitcherError.sshConfigUpdateFailed(error.localizedDescription)
        }
    }

    private static func setGitGlobal(key: String, value: String) throws {
        // #region agent log
        DebugLogger.log(
            hypothesisId: "C",
            location: "AccountSwitcher.swift:44",
            message: "Setting git global",
            data: [
                "key": key,
                "value": value
            ],
            runId: "run2"
        )
        // #endregion
        let output = try runCommand(
            "/usr/bin/git",
            arguments: ["config", "--global", key, value]
        )
        if !output.isEmpty {
            throw AccountSwitcherError.commandFailed(
                command: "git config --global \(key) <value>",
                output: output
            )
        }
    }

    @discardableResult
    private static func runCommand(_ command: String, arguments: [String]) throws -> String {
        // #region agent log
        DebugLogger.log(
            hypothesisId: "C",
            location: "AccountSwitcher.swift:63",
            message: "Run command start",
            data: [
                "command": command,
                "arguments": arguments.joined(separator: " ")
            ],
            runId: "run2"
        )
        // #endregion
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            // #region agent log
            DebugLogger.log(
                hypothesisId: "C",
                location: "AccountSwitcher.swift:90",
                message: "Run command failed",
                data: [
                    "status": String(process.terminationStatus),
                    "output": errorOutput.isEmpty ? output : errorOutput
                ],
                runId: "run2"
            )
            // #endregion
            throw AccountSwitcherError.commandFailed(
                command: ([command] + arguments).joined(separator: " "),
                output: errorOutput.isEmpty ? output : errorOutput
            )
        }

        // #region agent log
        DebugLogger.log(
            hypothesisId: "C",
            location: "AccountSwitcher.swift:105",
            message: "Run command success",
            data: [
                "status": String(process.terminationStatus),
                "output": errorOutput.isEmpty ? output : errorOutput
            ],
            runId: "run2"
        )
        // #endregion
        return errorOutput.isEmpty ? output : errorOutput
    }
}
