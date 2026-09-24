import AppKit

enum MouseZone { case far, middle, near }

struct MouseSnapshot {
    let point: NSPoint
    let dx: CGFloat
    let dy: CGFloat
    let distance: CGFloat
    let speed: CGFloat
    let zone: MouseZone
    var directionIndex: Int {
        let raw = atan2(Double(dx), Double(dy)) * 180 / .pi
        return (Int((raw / 22.5).rounded()) % 16 + 16) % 16
    }
}

final class MouseInteractionManager {
    private var previousPoint: NSPoint?
    private var previousTime: TimeInterval = 0
    private var clickTimes: [TimeInterval] = []

    func sample(window: NSWindow, now: TimeInterval) -> MouseSnapshot {
        let point = NSEvent.mouseLocation
        let center = NSPoint(x: window.frame.midX, y: window.frame.midY)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)
        let speed: CGFloat
        if let previousPoint, now > previousTime {
            speed = hypot(point.x - previousPoint.x, point.y - previousPoint.y) / CGFloat(now - previousTime)
        } else { speed = 0 }
        previousPoint = point
        previousTime = now
        let zone: MouseZone = distance < PetConfig.approachDistance ? .near :
            (distance < PetConfig.senseDistance ? .middle : .far)
        return MouseSnapshot(point: point, dx: dx, dy: dy, distance: distance, speed: speed, zone: zone)
    }

    func recordClick(now: TimeInterval) -> Int {
        clickTimes.removeAll { now - $0 > PetConfig.clickWindow }
        clickTimes.append(now)
        return clickTimes.count
    }

    func resetClicks() { clickTimes.removeAll() }
}
