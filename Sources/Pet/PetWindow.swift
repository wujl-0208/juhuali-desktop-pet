import AppKit

final class PetSpriteView: NSView {
    var image: NSImage? { didSet { if image !== oldValue { needsDisplay = true } } }
    var onMouseDown: ((NSEvent) -> Void)?
    var onMouseDragged: ((NSEvent) -> Void)?
    var onMouseUp: ((NSEvent) -> Void)?
    var onRightMouseDown: ((NSEvent) -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        image?.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
    }
    override func mouseDown(with event: NSEvent) { onMouseDown?(event) }
    override func mouseDragged(with event: NSEvent) { onMouseDragged?(event) }
    override func mouseUp(with event: NSEvent) { onMouseUp?(event) }
    override func rightMouseDown(with event: NSEvent) { onRightMouseDown?(event) }
}

final class PetWindow: NSPanel {
    let spriteView = PetSpriteView()

    init(frame: NSRect, alwaysOnTop: Bool) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        level = alwaysOnTop ? .floating : .normal
        acceptsMouseMovedEvents = false
        contentView = spriteView
        orderFrontRegardless()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
