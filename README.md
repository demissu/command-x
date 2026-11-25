<p align="center">
  <img src="AppIcon.png" width="128" alt="Command X app icon">
</p>

<h1 align="center">Command X</h1>

<p align="center"><strong>Cut. Paste. Move.</strong></p>
<p align="center">Windows-style file cutting, right in macOS Finder.</p>

<p align="center">
  <a href="https://github.com/demissu/command-x/releases/latest"><img src="https://img.shields.io/github/v/release/demissu/command-x?style=flat-square&label=release" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-native-F05138?style=flat-square" alt="Swift">
</p>

<p align="center">
  <a href="https://github.com/demissu/command-x/releases/latest"><strong>Download Command X</strong></a> ·
  <a href="#installation">Installation</a> ·
  <a href="https://github.com/demissu/command-x/issues">Report an issue</a>
</p>

---

## A simpler way to move files

Forget the extra Option key. Select files in Finder, cut them, navigate to your destination and paste. Command X uses Finder's native move operation.

| Shortcut | Action |
| :--- | :--- |
| <kbd>⌘</kbd> + <kbd>X</kbd> | Cut selected files |
| <kbd>⌘</kbd> + <kbd>V</kbd> | Move pending cut files |
| <kbd>Esc</kbd> | Cancel a pending cut |

## Features

- Native Swift menu bar utility.
- Multiple file selection.
- Launch at login (macOS 13 or later).
- Automatic keyboard listener recovery.
- No network requests, keyboard logging or telemetry implemented.

## Installation

1. Open the [latest release](https://github.com/demissu/command-x/releases/latest) and download the macOS application ZIP from Assets, if available.
2. Extract the archive and move **Command X.app** to **Applications** before launching.
3. Open the app and grant Accessibility permission in **System Settings → Privacy & Security → Accessibility**.
4. Select a noncritical file in Finder and try cutting and pasting it.

If needed, check Input Monitoring and use **Restart Keyboard Listener** in the menu bar.

> [!IMPORTANT]
> Command X uses ad-hoc code signing and is not Apple-notarized. macOS may show security warnings or prevent it from opening. Tested on Apple Silicon; other configurations are not verified. Do not disable system-wide security protections.

## Build from source

Requires macOS, Swift and Xcode Command Line Tools.

```sh
xcode-select --install
git clone https://github.com/demissu/command-x.git
cd command-x
chmod +x build.sh
./build.sh
```

The script builds, ad-hoc signs and opens the app. Quit it before moving it to Applications. Keep only one installed copy and grant permissions to that copy.

## Troubleshooting

If keyboard shortcuts stop working after rebuilding, quit Command X, remove stale Accessibility entries and keep only one installed app. Register the installed app and reset its specific permission records:

```sh
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Command X.app"
tccutil reset Accessibility com.commandx.utility
tccutil reset ListenEvent com.commandx.utility
tccutil reset PostEvent com.commandx.utility
```

Restart macOS if necessary, open the app from Applications and grant permissions again. Ad-hoc signatures can cause permission mismatches after rebuilds.

## Privacy and known limitations

Command X uses a session keyboard event tap, checks the active application and Finder accessibility focus, and reads file URLs from the system clipboard.

- Cutting replaces the clipboard through Finder's copy operation.
- Cut file icons are not visually dimmed.
- Pasting before the clipboard update is detected may behave as a normal paste.
- Move completion is not independently verified by the utility.

Test with noncritical files first.

## Feedback and contributions

Found a bug or have an idea? [Open an issue](https://github.com/demissu/command-x/issues). Include your macOS version, Mac architecture and steps to reproduce the issue. Avoid sharing private file paths or sensitive information.

See the [changelog](CHANGELOG.md) for release history.

## License and naming

See [LICENSE](LICENSE). MIT licensing was proposed for publication, subject to repository owner's approval. Command X is an independent project and is not affiliated with other utilities with similar names.

---

<p align="center"><strong>Cut. Paste. Move.</strong><br>Made for macOS.</p>
