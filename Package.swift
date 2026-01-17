// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitHubAccountSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "GitHubAccountSwitcherApp",
            targets: ["GitHubAccountSwitcherApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "GitHubAccountSwitcherApp"
        )
    ]
)

