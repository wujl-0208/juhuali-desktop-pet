import AppKit

/// All tunable motion, timing and interaction values live here.
enum PetConfig {
    static let atlasColumns = 8
    static let atlasRows = 11
    static let cellWidth = 192
    static let cellHeight = 208
    static let baseWidth: CGFloat = 96
    static let baseHeight: CGFloat = 104
    static let minScale: Double = 0.70
    static let maxScale: Double = 1.80

    static let senseDistance: CGFloat = 290
    static let approachDistance: CGFloat = 135
    static let stopDistance: CGFloat = 66
    static let wakeDistance: CGFloat = 150
    static let walkSpeed: CGFloat = 26
    static let runSpeed: CGFloat = 49
    static let approachSpeed: CGFloat = 25
    static let approachDuration: TimeInterval = 3.0
    static let approachCooldown: TimeInterval = 22
    static let jumpVelocity: CGFloat = 235
    static let gravity: CGFloat = 720
    static let edgePadding: CGFloat = 2
    static let dragThreshold: CGFloat = 4
    static let clickWindow: TimeInterval = 2
    static let doubleClickDelay: TimeInterval = 0.30
    static let sleepAfter: TimeInterval = 150
    static let randomInterval: ClosedRange<TimeInterval> = 12...24
    static let roamDuration: ClosedRange<TimeInterval> = 1.3...3.4
    static let runDuration: ClosedRange<TimeInterval> = 0.7...1.3
    static let activeTick: TimeInterval = 1.0 / 20.0
    static let idleTick: TimeInterval = 1.0 / 8.0
    static let sleepTick: TimeInterval = 0.5
    static let hitAlphaThreshold: CGFloat = 0.05

    static let idleFPS = 4.0
    static let walkFPS = 6.0
    static let runFPS = 9.0
    static let jumpFPS = 8.0
    static let reactionFPS = 7.0
    static let sleepFPS = 1.0
}
