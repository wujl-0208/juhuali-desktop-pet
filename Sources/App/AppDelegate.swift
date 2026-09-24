import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pet: PetController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard let pet = PetController(loadResources: true) else {
            let alert = NSAlert()
            alert.messageText = "无法载入菊花梨素材"
            alert.informativeText = "请确认应用包中的 Animations/spritesheet.png 完整。"
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        self.pet = pet
        if CommandLine.arguments.contains("--preview-sleep") {
            pet.restPet()
        }
        if CommandLine.arguments.contains("--preview-settings") {
            pet.showSettings()
        }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "🌼"
        item.button?.toolTip = "菊花梨"
        let menu = NSMenu(title: "菊花梨")
        func add(_ title: String, action: Selector) {
            let row = NSMenuItem(title: title, action: action, keyEquivalent: "")
            row.target = pet
            menu.addItem(row)
        }
        add("设置…", action: #selector(PetController.showSettings))
        add("让菊花梨休息", action: #selector(PetController.restPet))
        add("唤醒", action: #selector(PetController.wakePet))
        menu.addItem(.separator())
        add("退出桌宠", action: #selector(PetController.quitPet))
        item.menu = menu
        statusItem = item
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
