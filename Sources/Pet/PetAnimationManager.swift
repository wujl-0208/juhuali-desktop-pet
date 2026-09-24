import AppKit
import ImageIO

struct SpriteFrame: Hashable {
    let row: Int
    let column: Int
}

struct AnimationClip {
    let name: String
    let frames: [SpriteFrame]
    let fps: Double
    let loops: Bool
    let nextState: PetState?

    init(_ name: String, row: Int, columns: [Int], fps: Double, loops: Bool = true, nextState: PetState? = nil) {
        self.name = name
        self.frames = columns.map { SpriteFrame(row: row, column: $0) }
        self.fps = fps
        self.loops = loops
        self.nextState = nextState
    }
}

/// The atlas is decoded once. Every visible frame and its alpha map are cached.
final class PetAnimationManager {
    private let atlas: CGImage
    private var cache: [SpriteFrame: (image: NSImage, bitmap: NSBitmapImageRep)] = [:]
    private(set) var clip = AnimationClip("idle", row: 0, columns: Array(0...5), fps: PetConfig.idleFPS)
    private(set) var frameIndex = 0
    private var clipStart: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var didFinish = false

    init?() {
        guard let url = Bundle.main.url(forResource: "spritesheet", withExtension: "png", subdirectory: "Animations"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == PetConfig.cellWidth * PetConfig.atlasColumns,
              image.height == PetConfig.cellHeight * PetConfig.atlasRows else { return nil }
        atlas = image
        // Decode all used cells during startup, not during animation.
        let counts = [7, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8]
        for (row, count) in counts.enumerated() {
            for column in 0..<count { _ = cached(SpriteFrame(row: row, column: column)) }
        }
    }

    private func cached(_ frame: SpriteFrame) -> (image: NSImage, bitmap: NSBitmapImageRep) {
        if let existing = cache[frame] { return existing }
        let rect = CGRect(x: frame.column * PetConfig.cellWidth,
                          y: frame.row * PetConfig.cellHeight,
                          width: PetConfig.cellWidth,
                          height: PetConfig.cellHeight)
        let crop = atlas.cropping(to: rect)!
        let pair = (image: NSImage(cgImage: crop, size: NSSize(width: PetConfig.cellWidth, height: PetConfig.cellHeight)),
                    bitmap: NSBitmapImageRep(cgImage: crop))
        cache[frame] = pair
        return pair
    }

    var currentImage: NSImage { cached(clip.frames[frameIndex]).image }
    var currentBitmap: NSBitmapImageRep { cached(clip.frames[frameIndex]).bitmap }

    func play(_ newClip: AnimationClip, at now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        if clip.name == newClip.name { return }
        clip = newClip
        frameIndex = 0
        clipStart = now
        didFinish = false
    }

    func showLook(index: Int) {
        let index = (index % 16 + 16) % 16
        let frame = SpriteFrame(row: index < 8 ? 9 : 10, column: index % 8)
        if clip.name == "look-\(index)" { return }
        clip = AnimationClip("look-\(index)", row: frame.row, columns: [frame.column], fps: 1)
        frameIndex = 0
        didFinish = false
    }

    /// Returns whether the visible frame changed and whether a one-shot ended.
    func advance(now: TimeInterval, speed: Double) -> (changed: Bool, completed: Bool) {
        let steps = Int(max(0, now - clipStart) * clip.fps * speed)
        let next = clip.loops ? steps % clip.frames.count : min(steps, clip.frames.count - 1)
        let changed = next != frameIndex
        frameIndex = next
        let completed = !clip.loops && !didFinish && steps >= clip.frames.count
        if completed { didFinish = true }
        return (changed, completed)
    }

    func alpha(at viewPoint: NSPoint, viewSize: NSSize) -> CGFloat {
        guard viewSize.width > 0, viewSize.height > 0,
              viewPoint.x >= 0, viewPoint.y >= 0,
              viewPoint.x < viewSize.width, viewPoint.y < viewSize.height else { return 0 }
        let x = min(PetConfig.cellWidth - 1, max(0, Int(viewPoint.x / viewSize.width * CGFloat(PetConfig.cellWidth))))
        let y = min(PetConfig.cellHeight - 1, max(0, Int(viewPoint.y / viewSize.height * CGFloat(PetConfig.cellHeight))))
        return currentBitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0
    }
}
