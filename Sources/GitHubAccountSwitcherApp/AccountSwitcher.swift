import Foundation

enum AccountSwitcherError: LocalizedError {
    case commandFailed(command: String, output: String)
    case sshConfigUpdateFailed(String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(command, output):
            return "Command failed: \(command). \(output)"
        case let .sshConfigUpdateFailed(message):
            return "SSH config update failed: \(message)"
        }
    }
}

enum AccountSwitcher {
    static func switchTo(_ profile: AccountProfile) throws {
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
            throw AccountSwitcherError.commandFailed(
                command: ([command] + arguments).joined(separator: " "),
                output: errorOutput.isEmpty ? output : errorOutput
            )
        }

        return errorOutput.isEmpty ? output : errorOutput
    }
}

