<p align="center"><img src="AppIcon.png" width="128" alt="Command X icon"></p>

# Command X

**Cut. Paste. Move.**

A lightweight native macOS menu bar utility for Windows-style file cutting in Finder.

## Features

- Command + X: mark selected files for moving.
- Command + V: move marked files using Finder's native move operation.
- Escape: cancel the pending cut in Finder.
- Multiple file selection, launch at login, and keyboard listener recovery.
- No network access or telemetry implemented in the source.

## Build and install

Requires macOS, Swift and Xcode Command Line Tools (`xcode-select --install`). Tested by the developer on an Apple Silicon Mac; other configurations are not verified. Launch at login requires macOS 13 or later.

```sh
chmod +x build.sh
./build.sh
```

The script builds and ad-hoc signs `Command X.app` and opens it. Quit the app, move it to `/Applications`, remove any redundant app copies, and launch it from Applications. Grant Accessibility permission in System Settings > Privacy & Security. If needed, check Input Monitoring and restart the keyboard listener from the menu.

## Troubleshooting

If permissions stop working after rebuilding, quit the app and remove stale Accessibility entries. Keep only one installed copy. Register the installed app again and reset its specific permission records:

```sh
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Command X.app"
tccutil reset Accessibility com.commandx.utility
tccutil reset ListenEvent com.commandx.utility
tccutil reset PostEvent com.commandx.utility
```

Restart macOS if necessary, launch from Applications and grant permissions again. The app is not notarized; ad-hoc signatures can cause permission mismatches after rebuilds.

## Privacy and limitations

The app uses a session keyboard event tap, checks the active application and Finder accessibility focus, and reads file URLs from the system clipboard. It does not implement keyboard logging, network requests or telemetry. Cutting uses Finder's copy operation, so the clipboard is replaced. File icons are not dimmed. Very fast pasting before the clipboard update is detected may behave as normal paste. Move completion is not independently verified by the utility. Test with noncritical files first.

## License and naming

MIT license proposed for publication, subject to repository owner's approval. This is an independent project and is not affiliated with other utilities with similar names.
