# GitHub Account Switcher

A simple macOS menu bar application to switch between GitHub accounts seamlessly.

## Features

- **Global Git Identity**: Toggles `user.name` and `user.email` globally using `git config --global`.
- **SSH Key Switching**: Automatically updates `IdentityFile` in `~/.ssh/config` for your GitHub host aliases and `github.com`.
- **Identities Only**: Enforces `IdentitiesOnly yes` in SSH config to prevent `ssh-agent` from offering the wrong keys.
- **Configurable**: Define your profiles in a simple JSON file.
- **Persistence**: Remembers your last selected account across app restarts.

## Setup

1. **Configure Profiles**:
   Copy `config.sample.json` to `config.json` in the project root:
   ```bash
   cp config.sample.json config.json
   ```
   Edit `config.json` with your account details and SSH key paths.

2. **SSH Config**:
   Ensure your `~/.ssh/config` has blocks for the host aliases defined in your `config.json` (e.g., `Host github-personal`). The app will update these blocks automatically.

## How to Run

From the terminal:
```bash
swift run GitHubAccountSwitcherApp
```

The app will appear in your macOS menu bar with a profile icon.

## How it Works

When you select a profile from the menu:
1. It runs `git config --global user.name "..."` and `git config --global user.email "..."`.
2. It parses `~/.ssh/config` and updates the `IdentityFile` line for every host alias in your profile, plus `github.com`.
3. It ensures `IdentitiesOnly yes` is set for those hosts so SSH always uses the specific key provided.

## Configuration File Locations

The app looks for `config.json` in the following order:
1. Environment variable `GITHUB_ACCOUNT_SWITCHER_CONFIG`.
2. `~/Library/Application Support/GitHubAccountSwitcher/config.json`.
3. `./config.json` (current working directory).

