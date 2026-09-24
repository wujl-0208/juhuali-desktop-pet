import AppKit

final class SettingsWindowController: NSWindowController {
    private let settings: PetSettings
    private let sizeSlider = NSSlider(value: 1, minValue: PetConfig.minScale, maxValue: PetConfig.maxScale,
                                      target: nil, action: nil)
    private let speedSlider = NSSlider(value: 1, minValue: 0.5, maxValue: 1.6,
                                       target: nil, action: nil)
    private let sizeValue = NSTextField(labelWithString: "")
    private let speedValue = NSTextField(labelWithString: "")
    private let autoButton = NSButton(checkboxWithTitle: "自动移动", target: nil, action: nil)
    private let followButton = NSButton(checkboxWithTitle: "跟随鼠标方向", target: nil, action: nil)
    private let proximityButton = NSButton(checkboxWithTitle: "鼠标靠近互动", target: nil, action: nil)
    private let topButton = NSButton(checkboxWithTitle: "始终置顶", target: nil, action: nil)
    private let soundButton = NSButton(checkboxWithTitle: "音效（预留）", target: nil, action: nil)

    init(settings: PetSettings) {
        self.settings = settings
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 370),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered, defer: false)
        window.title = "菊花梨设置"
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildView(in: window)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildView(in window: NSWindow) {
        guard let view = window.contentView else { return }
        func label(_ text: String, y: CGFloat) {
            let field = NSTextField(labelWithString: text)
            field.font = .systemFont(ofSize: 13, weight: .medium)
            field.frame = NSRect(x: 24, y: y, width: 120, height: 22)
            view.addSubview(field)
        }
        label("桌宠大小", y: 320)
        sizeSlider.frame = NSRect(x: 145, y: 317, width: 190, height: 24)
        sizeValue.frame = NSRect(x: 340, y: 320, width: 50, height: 22)
        label("动画速度", y: 275)
        speedSlider.frame = NSRect(x: 145, y: 272, width: 190, height: 24)
        speedValue.frame = NSRect(x: 340, y: 275, width: 50, height: 22)
        sizeSlider.target = self; sizeSlider.action = #selector(scaleChanged)
        speedSlider.target = self; speedSlider.action = #selector(speedChanged)
        view.addSubview(sizeSlider); view.addSubview(sizeValue)
        view.addSubview(speedSlider); view.addSubview(speedValue)

        let controls: [(NSButton, CGFloat, Selector)] = [
            (autoButton, 228, #selector(autoChanged)),
            (followButton, 193, #selector(followChanged)),
            (proximityButton, 158, #selector(proximityChanged)),
            (topButton, 123, #selector(topChanged)),
            (soundButton, 88, #selector(soundChanged))
        ]
        for (button, y, selector) in controls {
            button.frame = NSRect(x: 24, y: y, width: 340, height: 24)
            button.target = self
            button.action = selector
            view.addSubview(button)
        }
        let note = NSTextField(labelWithString: "参数保存在本机。音效开关为后续动作音效预留。")
        note.font = .systemFont(ofSize: 11)
        note.textColor = .secondaryLabelColor
        note.frame = NSRect(x: 24, y: 35, width: 350, height: 20)
        view.addSubview(note)
    }

    func refresh() {
        sizeSlider.doubleValue = settings.scale
        speedSlider.doubleValue = settings.animationSpeed
        sizeValue.stringValue = String(format: "%.0f%%", settings.scale * 100)
        speedValue.stringValue = String(format: "%.1f×", settings.animationSpeed)
        autoButton.state = settings.autoMovement ? .on : .off
        followButton.state = settings.mouseFollowing ? .on : .off
        proximityButton.state = settings.proximityInteraction ? .on : .off
        topButton.state = settings.alwaysOnTop ? .on : .off
        soundButton.state = settings.soundEnabled ? .on : .off
    }

    @objc private func scaleChanged() { settings.scale = sizeSlider.doubleValue }
    @objc private func speedChanged() { settings.animationSpeed = speedSlider.doubleValue }
    @objc private func autoChanged() { settings.autoMovement = autoButton.state == .on }
    @objc private func followChanged() { settings.mouseFollowing = followButton.state == .on }
    @objc private func proximityChanged() { settings.proximityInteraction = proximityButton.state == .on }
    @objc private func topChanged() { settings.alwaysOnTop = topButton.state == .on }
    @objc private func soundChanged() { settings.soundEnabled = soundButton.state == .on }
}
