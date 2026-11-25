import AppKit
import ApplicationServices
import ServiceManagement

final class App: NSObject, NSApplicationDelegate {
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    var status: NSStatusItem!
    var cutChange: Int?
    var pending = false
    var generation = 0
    var enabled = true
    var count = 0
    var timer: Timer?
    var toggleItem: NSMenuItem!
    var loginItem: NSMenuItem!
    var countItem: NSMenuItem!
    var healthItem: NSMenuItem!
    let marker: Int64 = 0x434D4458
    let pasteboard = NSPasteboard.general

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        refresh()
        let menu = NSMenu()
        toggleItem = menu.addItem(withTitle: "Disable Command X", action: #selector(toggle), keyEquivalent: ""); toggleItem.target = self
        loginItem = menu.addItem(withTitle: "Launch at Login", action: #selector(login), keyEquivalent: ""); loginItem.target = self
        countItem = menu.addItem(withTitle: "No files cut", action: nil, keyEquivalent: "")
        healthItem = menu.addItem(withTitle: "Keyboard: checking", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Restart Keyboard Listener", action: #selector(restart), keyEquivalent: "").target = self
        menu.addItem(withTitle: "About Command X", action: #selector(about), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Cancel Cut", action: #selector(cancel), keyEquivalent: "") .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Command X", action: #selector(quit), keyEquivalent: "") .target = self
        status.menu = menu
        enable()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }; if let c = self.cutChange, c != self.pasteboard.changeCount { self.cancel() }; self.ensureListener(); self.refresh()
        }
    }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func cancel() { generation += 1; cutChange = nil; pending = false; count = 0; refresh() }
    func refresh() {
        healthItem?.title = !AXIsProcessTrusted() ? "Keyboard: permission required" : (tap.map { CGEvent.tapIsEnabled(tap: $0) } == true ? "Keyboard: active" : "Keyboard: inactive")
        let name = !enabled ? "pause.circle" : (cutChange == nil ? "command" : "scissors")
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Command X")
        image?.isTemplate = true
        status?.button?.image = image
        toggleItem?.title = enabled ? "Disable Command X" : "Enable Command X"
        countItem?.title = count == 0 ? "No files cut" : "Files cut: \(count)"
        if #available(macOS 13.0, *) { loginItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off }
        else { loginItem?.isHidden = true }
    }
    @objc func toggle() { enabled.toggle(); cancel(); if enabled { enable() }; refresh() }
    @objc func about() { let a = NSAlert(); a.messageText = "Command X 1.2"; a.informativeText = "Cut. Paste. Move."; a.runModal() }
    @objc func login() {
        if #available(macOS 13.0, *) {
            do { if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() } else { try SMAppService.mainApp.register() } }
            catch { let a = NSAlert(); a.messageText = "Login item could not be changed"; a.informativeText = error.localizedDescription; a.runModal() }
            refresh()
        }
    }
    func stopListener() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil; source = nil
    }
    @objc func restart() { cancel(); stopListener(); enable(); refresh() }
    func ensureListener() {
        guard enabled, AXIsProcessTrusted() else { return }
        if let tap, CFMachPortIsValid(tap) {
            if !CGEvent.tapIsEnabled(tap: tap) { CGEvent.tapEnable(tap: tap, enable: true) }
        } else { stopListener(); installListener(showAlert: false) }
    }
    @objc func enable() {
        if let tap, CFMachPortIsValid(tap) { CGEvent.tapEnable(tap: tap, enable: true); return }
        stopListener()
        installListener(showAlert: true)
    }
    func installListener(showAlert: Bool) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard (showAlert ? AXIsProcessTrustedWithOptions(options) : AXIsProcessTrusted()) else { return }
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, info in
            guard let info else { return Unmanaged.passUnretained(event) }
            return Unmanaged<App>.fromOpaque(info).takeUnretainedValue().handle(type, event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        if let tap {
            source = CFMachPortCreateRunLoopSource(nil, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        } else if showAlert {
            let alert = NSAlert(); alert.messageText = "Keyboard access unavailable"; alert.informativeText = "Check Accessibility and Input Monitoring in System Settings, then retry."; alert.runModal()
        }
    }
    func finderTextFocused() -> Bool {
        guard let finder = NSWorkspace.shared.frontmostApplication else { return true }
        let system = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(system, 0.15)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &value) == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return true }
        let element = unsafeBitCast(value, to: AXUIElement.self)
        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success else { return true }
        return ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"].contains(role as? String ?? "")
    }
    func send(_ key: CGKeyCode, _ flags: CGEventFlags) {
        for down in [true, false] {
            guard let e = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down) else { continue }
            e.flags = flags; e.setIntegerValueField(.eventSourceUserData, value: marker); e.post(tap: .cgSessionEventTap)
        }
    }
    func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput { if let tap { CGEvent.tapEnable(tap: tap, enable: true) }; return pass }
        guard event.getIntegerValueField(.eventSourceUserData) != marker else { return pass }
        guard enabled else { return pass }
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder" else { return pass }
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags.intersection([.maskCommand, .maskAlternate, .maskControl, .maskShift])
        if key == 53 { cancel(); return pass }
        guard flags == .maskCommand, [7, 8, 9].contains(key) else { return pass }
        if key == 8 { cancel(); return pass }
        if key == 9 && cutChange == nil { return pass }
        guard !finderTextFocused() else { return pass }
        if key == 7 {
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return nil }
            cancel(); pending = true
            let token = generation
            let before = pasteboard.changeCount
            send(8, .maskCommand)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self, self.pending, self.generation == token else { return }
                self.pending = false
                guard self.pasteboard.changeCount != before, self.pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else { return }
                self.cutChange = self.pasteboard.changeCount
                self.count = self.pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])?.count ?? 0
                self.refresh()
            }
            return nil
        }
        if key == 9, let cutChange {
            guard pasteboard.changeCount == cutChange else { cancel(); return pass }
            cancel(); send(9, [.maskCommand, .maskAlternate]); return nil
        }
        return pass
    }
}
let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
