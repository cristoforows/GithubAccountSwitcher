import Foundation

enum SSHConfigEditorError: LocalizedError {
    case invalidHomeDirectory
    case readFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidHomeDirectory:
            return "Home directory not found."
        case let .readFailed(message):
            return "Unable to read SSH config: \(message)"
        case let .writeFailed(message):
            return "Unable to write SSH config: \(message)"
        }
    }
}

enum SSHConfigEditor {
    static func updateIdentityFile(forHosts hosts: [String], identityFilePath: String) throws {
        let fileURL = try sshConfigURL()
        let expandedIdentityPath = expandTilde(in: identityFilePath)
        // #region agent log
        DebugLogger.log(
            hypothesisId: "D",
            location: "SSHConfigEditor.swift:24",
            message: "SSH config update start",
            data: [
                "path": fileURL.path,
                "hosts": hosts.joined(separator: ","),
                "identityPath": expandedIdentityPath
            ]
        )
        // #endregion

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try createSSHConfig(at: fileURL, forHosts: hosts, identityFilePath: expandedIdentityPath)
            // #region agent log
            DebugLogger.log(
                hypothesisId: "D",
                location: "SSHConfigEditor.swift:31",
                message: "SSH config created",
                data: [
                    "path": fileURL.path,
                    "hosts": hosts.joined(separator: ",")
                ],
                runId: "run2"
            )
            // #endregion
            return
        }

        let content: String
        do {
            content = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw SSHConfigEditorError.readFailed(error.localizedDescription)
        }

        let updated = updateContent(
            content,
            hosts: hosts,
            identityFilePath: expandedIdentityPath
        )

        do {
            try updated.content.write(to: fileURL, atomically: true, encoding: .utf8)
            // #region agent log
            DebugLogger.log(
                hypothesisId: "D",
                location: "SSHConfigEditor.swift:49",
                message: "SSH config updated",
                data: [
                    "path": fileURL.path,
                    "didUpdate": updated.didUpdate ? "true" : "false"
                ],
                runId: "run2"
            )
            // #endregion
        } catch {
            throw SSHConfigEditorError.writeFailed(error.localizedDescription)
        }
    }

    private static func sshConfigURL() throws -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if home.path.isEmpty {
            throw SSHConfigEditorError.invalidHomeDirectory
        }

        return home.appendingPathComponent(".ssh/config")
    }

    private static func createSSHConfig(
        at url: URL,
        forHosts hosts: [String],
        identityFilePath: String
    ) throws {
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        var lines: [String] = []
        for host in hosts {
            lines.append("Host \(host)")
            lines.append("  HostName github.com")
            lines.append("  User git")
            lines.append("  IdentityFile \(identityFilePath)")
            lines.append("")
        }

        let content = lines.joined(separator: "\n")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw SSHConfigEditorError.writeFailed(error.localizedDescription)
        }
    }

    private static func updateContent(
        _ content: String,
        hosts: [String],
        identityFilePath: String
    ) -> (content: String, didUpdate: Bool) {
        let targetHosts = Set(hosts)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var updatedLines: [String] = []
        var inTargetBlock = false
        var sawIdentityFile = false

        for line in lines {
            if let hostNames = parseHostLine(line) {
                if inTargetBlock && !sawIdentityFile {
                    updatedLines.append("  IdentityFile \(identityFilePath)")
                }

                inTargetBlock = !targetHosts.isDisjoint(with: hostNames)
                sawIdentityFile = false
                updatedLines.append(line)
                continue
            }

            if inTargetBlock, let updatedLine = updateIdentityLineIfNeeded(line, identityFilePath: identityFilePath) {
                updatedLines.append(updatedLine)
                sawIdentityFile = true
                continue
            }

            updatedLines.append(line)
        }

        if inTargetBlock && !sawIdentityFile {
            updatedLines.append("  IdentityFile \(identityFilePath)")
        }

        let hasTrailingNewline = content.hasSuffix("\n")
        let joined = updatedLines.joined(separator: "\n") + (hasTrailingNewline ? "\n" : "")
        let didUpdate = joined != content
        return (joined, didUpdate)
    }

    private static func parseHostLine(_ line: String) -> Set<String>? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().hasPrefix("host ") else {
            return nil
        }

        let hostList = trimmed.dropFirst(5)
            .split(whereSeparator: { $0 == " " || $0 == "\t" })
            .map(String.init)

        return Set(hostList)
    }

    private static func updateIdentityLineIfNeeded(
        _ line: String,
        identityFilePath: String
    ) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().hasPrefix("identityfile ") else {
            return nil
        }

        let leadingWhitespace = line.prefix { $0 == " " || $0 == "\t" }
        return "\(leadingWhitespace)IdentityFile \(identityFilePath)"
    }

    private static func expandTilde(in path: String) -> String {
        guard path.hasPrefix("~") else {
            return path
        }

        return (path as NSString).expandingTildeInPath
    }
}

