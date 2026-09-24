import AppKit

/// Window movement and jump physics stay independent of sprite animation.
final class MovementController {
    private weak var window: NSWindow?
    private(set) var facingRight = true
    private(set) var groundY: CGFloat = 0
    private var verticalVelocity: CGFloat = 0
    private(set) var isJumping = false

    init(window: NSWindow) {
        self.window = window
        groundY = window.frame.minY
    }

    private func targetScreen(for rect: NSRect) -> NSScreen? {
        NSScreen.screens.max { first, second in
            first.frame.intersection(rect).width * first.frame.intersection(rect).height <
            second.frame.intersection(rect).width * second.frame.intersection(rect).height
        } ?? NSScreen.main
    }

    func visibleBounds() -> NSRect {
        guard let window else { return NSScreen.main?.visibleFrame ?? .zero }
        return targetScreen(for: window.frame)?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
    }

    func clampToVisibleArea(updateGround: Bool = false) {
        guard let window else { return }
        let screen = visibleBounds()
        var frame = window.frame
        let pad = PetConfig.edgePadding
        frame.origin.x = min(max(frame.origin.x, screen.minX + pad), screen.maxX - frame.width - pad)
        frame.origin.y = min(max(frame.origin.y, screen.minY + pad), screen.maxY - frame.height - pad)
        window.setFrameOrigin(frame.origin)
        if updateGround { groundY = frame.minY }
    }

    func setFacing(toward x: CGFloat) {
        guard let window else { return }
        if abs(x - window.frame.midX) > 12 { facingRight = x > window.frame.midX }
    }

    @discardableResult
    func move(horizontal speed: CGFloat, dt: TimeInterval) -> Bool {
        guard let window, speed != 0 else { return false }
        var frame = window.frame
        frame.origin.x += speed * CGFloat(min(dt, 0.1))
        let screen = visibleBounds()
        let minX = screen.minX + PetConfig.edgePadding
        let maxX = screen.maxX - frame.width - PetConfig.edgePadding
        let hit = frame.origin.x <= minX || frame.origin.x >= maxX
        frame.origin.x = min(max(frame.origin.x, minX), maxX)
        window.setFrameOrigin(frame.origin)
        if speed > 0 { facingRight = true } else { facingRight = false }
        if hit { facingRight.toggle() }
        return hit
    }

    func startJump() {
        guard !isJumping, let window else { return }
        groundY = window.frame.minY
        verticalVelocity = PetConfig.jumpVelocity
        isJumping = true
    }

    @discardableResult
    func stepJump(dt: TimeInterval) -> Bool {
        guard isJumping, let window else { return false }
        let step = CGFloat(min(dt, 0.1))
        verticalVelocity -= PetConfig.gravity * step
        var frame = window.frame
        frame.origin.y += verticalVelocity * step
        let ceiling = visibleBounds().maxY - frame.height - PetConfig.edgePadding
        if frame.origin.y > ceiling {
            frame.origin.y = ceiling
            verticalVelocity = min(0, verticalVelocity)
        }
        if frame.origin.y <= groundY {
            frame.origin.y = groundY
            verticalVelocity = 0
            isJumping = false
            window.setFrameOrigin(frame.origin)
            return true
        }
        window.setFrameOrigin(frame.origin)
        return false
    }

    func finishDrag(at origin: NSPoint) {
        guard let window else { return }
        isJumping = false
        verticalVelocity = 0
        window.setFrameOrigin(origin)
        clampToVisibleArea(updateGround: true)
    }

    func resize(to size: NSSize) {
        guard let window else { return }
        var frame = window.frame
        frame.origin.y -= size.height - frame.height
        frame.size = size
        window.setFrame(frame, display: true)
        clampToVisibleArea(updateGround: true)
    }
}
