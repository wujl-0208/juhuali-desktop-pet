import AppKit

final class PetController: NSObject {
    let window: PetWindow
    private let animator: PetAnimationManager
    private let stateMachine = PetStateMachine()
    private let mouse = MouseInteractionManager()
    private let settings = PetSettings.shared
    private let movement: MovementController
    private var timer: Timer?
    private var lastTick = ProcessInfo.processInfo.systemUptime
    private var lastInteraction = ProcessInfo.processInfo.systemUptime
    private var nextRandom = ProcessInfo.processInfo.systemUptime + 15
    private var movementEnds = 0.0
    private var approachEnds = 0.0
    private var nextApproach = 0.0
    private var manualSleepNeedsMouseExit = false
    private var lastDirectionIndex = -1
    private var lastFacingRight = true
    private var reactionClicks = 1
    private var downMouse: NSPoint?
    private var dragOffset = NSPoint.zero
    private var dragging = false
    private var pendingClick: DispatchWorkItem?
    private var settingsWindow: SettingsWindowController?

    var currentState: PetState { stateMachine.state }

    init?(loadResources: Bool) {
        guard let animator = PetAnimationManager() else { return nil }
        self.animator = animator
        let scale = CGFloat(PetSettings.shared.scale)
        let size = NSSize(width: PetConfig.baseWidth * scale, height: PetConfig.baseHeight * scale)
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 1000, height: 700)
        let frame = NSRect(x: visible.maxX - size.width - 150, y: visible.minY + 4,
                           width: size.width, height: size.height)
        window = PetWindow(frame: frame, alwaysOnTop: PetSettings.shared.alwaysOnTop)
        movement = MovementController(window: window)
        super.init()
        window.spriteView.image = animator.currentImage
        window.spriteView.onMouseDown = { [weak self] event in self?.mouseDown(event) }
        window.spriteView.onMouseDragged = { [weak self] event in self?.mouseDragged(event) }
        window.spriteView.onMouseUp = { [weak self] event in self?.mouseUp(event) }
        window.spriteView.onRightMouseDown = { [weak self] event in self?.rightMouseDown(event) }
        stateMachine.onChange = { [weak self] old, new in self?.stateChanged(from: old, to: new) }
        settings.onChange = { [weak self] in self?.applySettings() }
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        scheduleTick()
    }

    deinit {
        timer?.invalidate()
        pendingClick?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func scheduleTick() {
        timer?.invalidate()
        let interval: TimeInterval
        switch stateMachine.state {
        case .sleep: interval = PetConfig.sleepTick
        case .idle, .lookMouse: interval = PetConfig.idleTick
        default: interval = PetConfig.activeTick
        }
        let next = Timer(timeInterval: interval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }

    private func stateChanged(from old: PetState, to new: PetState) {
        let now = ProcessInfo.processInfo.systemUptime
        switch new {
        case .idle:
            animator.play(AnimationClip("idle", row: 0, columns: Array(0...5), fps: PetConfig.idleFPS), at: now)
            nextRandom = now + Double.random(in: PetConfig.randomInterval)
        case .lookMouse:
            movementEnds = now + 2.5
        case .approachMouse:
            approachEnds = now + PetConfig.approachDuration
            nextApproach = now + PetConfig.approachCooldown
            playDirectionalMotion(state: new, now: now)
        case .walk:
            movementEnds = now + Double.random(in: PetConfig.roamDuration)
            playDirectionalMotion(state: new, now: now)
        case .run:
            movementEnds = now + Double.random(in: PetConfig.runDuration)
            playDirectionalMotion(state: new, now: now)
        case .jump:
            movement.startJump()
            animator.play(AnimationClip("jump", row: 4, columns: Array(0...4), fps: PetConfig.jumpFPS), at: now)
        case .doubleClickReaction:
            movement.startJump()
            animator.play(AnimationClip("double-click", row: 4, columns: Array(0...4), fps: PetConfig.jumpFPS), at: now)
        case .clickReaction:
            playClickReaction(now: now)
        case .rightClickReaction:
            animator.play(AnimationClip("right-click", row: 6, columns: Array(0...5),
                                         fps: PetConfig.reactionFPS, loops: false, nextState: .idle), at: now)
        case .dragged:
            animator.play(AnimationClip("dragged", row: 4, columns: [2, 3], fps: 3), at: now)
        case .drowsy:
            animator.play(AnimationClip("drowsy", row: 0, columns: [0, 1, 2],
                                         fps: 3, loops: false, nextState: .sleep), at: now)
        case .sleep:
            animator.play(AnimationClip("sleep", row: 0, columns: [2], fps: PetConfig.sleepFPS), at: now)
        case .wakeUp:
            animator.play(AnimationClip("wake", row: 0, columns: [2, 1, 0],
                                         fps: 5, loops: false, nextState: .idle), at: now)
        }
        window.spriteView.image = animator.currentImage
        scheduleTick()
    }

    private func playDirectionalMotion(state: PetState, now: TimeInterval) {
        let right = movement.facingRight
        let row = right ? 1 : 2
        let base = state == .run ? PetConfig.runFPS : PetConfig.walkFPS
        animator.play(AnimationClip("\(state.rawValue)-\(right)", row: row,
                                    columns: Array(0...7), fps: base), at: now)
        lastFacingRight = right
        window.spriteView.image = animator.currentImage
    }

    private func playClickReaction(now: TimeInterval) {
        let row: Int
        let columns: [Int]
        if reactionClicks == 1 { row = 3; columns = Array(0...3) }
        else if reactionClicks <= 3 { row = 8; columns = Array(0...5) }
        else { row = movement.facingRight ? 1 : 2; columns = Array(0...7) }
        animator.play(AnimationClip("click-\(reactionClicks)-\(now)", row: row, columns: columns,
                                    fps: PetConfig.reactionFPS, loops: false, nextState: .idle), at: now)
        window.spriteView.image = animator.currentImage
    }

    @objc private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(0.15, max(0, now - lastTick))
        lastTick = now
        let snapshot = mouse.sample(window: window, now: now)
        updateHitTesting(mousePoint: snapshot.point)

        if [.sleep, .drowsy].contains(stateMachine.state) {
            if manualSleepNeedsMouseExit && snapshot.zone == .far {
                manualSleepNeedsMouseExit = false
            } else if !manualSleepNeedsMouseExit && settings.proximityInteraction &&
                snapshot.distance < PetConfig.wakeDistance {
                _ = stateMachine.send(.wake)
                lastInteraction = now
            }
        } else if ![.dragged, .jump, .doubleClickReaction, .clickReaction, .rightClickReaction, .wakeUp].contains(stateMachine.state) {
            updateProximity(snapshot, now: now)
            updateRandomBehavior(snapshot, now: now)
        }

        updateMovement(snapshot, dt: dt, now: now)
        let result = animator.advance(now: now, speed: settings.animationSpeed)
        if result.changed { window.spriteView.image = animator.currentImage }
        if result.completed { _ = stateMachine.send(.animationEnded) }
    }

    private func updateProximity(_ snapshot: MouseSnapshot, now: TimeInterval) {
        guard settings.proximityInteraction else {
            _ = stateMachine.send(.mouseFar)
            return
        }
        switch snapshot.zone {
        case .far:
            if stateMachine.state != .lookMouse || now >= movementEnds {
                _ = stateMachine.send(.mouseFar)
            }
        case .middle:
            if settings.mouseFollowing { _ = stateMachine.send(.mouseMiddle) }
        case .near:
            if settings.mouseFollowing { _ = stateMachine.send(.mouseMiddle) }
            if settings.autoMovement && settings.mouseFollowing && now >= nextApproach &&
                snapshot.speed < 650 && snapshot.distance > PetConfig.stopDistance {
                _ = stateMachine.send(.mouseNear)
            }
        }
        if stateMachine.state == .lookMouse {
            if lastDirectionIndex != snapshot.directionIndex {
                lastDirectionIndex = snapshot.directionIndex
                animator.showLook(index: snapshot.directionIndex)
                window.spriteView.image = animator.currentImage
            }
        }
    }

    private func updateRandomBehavior(_ snapshot: MouseSnapshot, now: TimeInterval) {
        guard settings.autoMovement, snapshot.zone == .far else { return }
        if now - lastInteraction > PetConfig.sleepAfter {
            _ = stateMachine.send(.sleepTimeout)
            return
        }
        guard now >= nextRandom, stateMachine.state == .idle else { return }
        nextRandom = now + Double.random(in: PetConfig.randomInterval)
        switch Int.random(in: 0..<10) {
        case 0, 1, 2, 3: _ = stateMachine.send(.randomWalk)
        case 4: _ = stateMachine.send(.randomRun)
        case 5: _ = stateMachine.send(.randomJump)
        default: _ = stateMachine.send(.randomLook)
        }
        if stateMachine.state == .walk || stateMachine.state == .run {
            movement.setFacing(toward: window.frame.midX + Bool.random().sign)
            playDirectionalMotion(state: stateMachine.state, now: now)
        }
    }

    private func updateMovement(_ snapshot: MouseSnapshot, dt: TimeInterval, now: TimeInterval) {
        switch stateMachine.state {
        case .walk, .run:
            guard settings.autoMovement else { _ = stateMachine.send(.movementEnded); return }
            let speed = stateMachine.state == .run ? PetConfig.runSpeed : PetConfig.walkSpeed
            let edge = movement.move(horizontal: movement.facingRight ? speed : -speed, dt: dt)
            if edge { playDirectionalMotion(state: stateMachine.state, now: now) }
            if now >= movementEnds { _ = stateMachine.send(.movementEnded) }
        case .approachMouse:
            if now >= approachEnds || snapshot.speed > 800 || snapshot.distance <= PetConfig.stopDistance ||
                snapshot.zone == .far || !settings.autoMovement {
                _ = stateMachine.send(.movementEnded)
                return
            }
            movement.setFacing(toward: snapshot.point.x)
            _ = movement.move(horizontal: snapshot.dx >= 0 ? PetConfig.approachSpeed : -PetConfig.approachSpeed, dt: dt)
            if lastFacingRight != movement.facingRight { playDirectionalMotion(state: .approachMouse, now: now) }
        case .lookMouse:
            if snapshot.zone == .far && now >= movementEnds { _ = stateMachine.send(.movementEnded) }
        case .jump, .doubleClickReaction:
            if movement.stepJump(dt: dt) { _ = stateMachine.send(.landed) }
        case .clickReaction:
            if reactionClicks >= 4 {
                let direction: CGFloat = snapshot.dx >= 0 ? -1 : 1
                _ = movement.move(horizontal: direction * PetConfig.walkSpeed, dt: dt)
            }
        default: break
        }
    }

    private func updateHitTesting(mousePoint: NSPoint) {
        let local = NSPoint(x: mousePoint.x - window.frame.minX,
                            y: window.frame.maxY - mousePoint.y)
        let alpha = animator.alpha(at: local, viewSize: window.frame.size)
        let shouldIgnore = alpha < PetConfig.hitAlphaThreshold
        if window.ignoresMouseEvents != shouldIgnore { window.ignoresMouseEvents = shouldIgnore }
    }

    private func mouseDown(_ event: NSEvent) {
        manualSleepNeedsMouseExit = false
        downMouse = NSEvent.mouseLocation
        dragOffset = NSPoint(x: downMouse!.x - window.frame.minX, y: downMouse!.y - window.frame.minY)
        dragging = false
    }

    private func mouseDragged(_ event: NSEvent) {
        guard let downMouse else { return }
        let point = NSEvent.mouseLocation
        if !dragging && hypot(point.x - downMouse.x, point.y - downMouse.y) >= PetConfig.dragThreshold {
            dragging = true
            pendingClick?.cancel()
            _ = stateMachine.send(.dragStart)
        }
        if dragging {
            window.setFrameOrigin(NSPoint(x: point.x - dragOffset.x, y: point.y - dragOffset.y))
        }
    }

    private func mouseUp(_ event: NSEvent) {
        defer { downMouse = nil }
        let now = ProcessInfo.processInfo.systemUptime
        lastInteraction = now
        if dragging {
            dragging = false
            movement.finishDrag(at: window.frame.origin)
            _ = stateMachine.send(.dragEnd)
            return
        }
        if event.clickCount >= 2 {
            pendingClick?.cancel()
            pendingClick = nil
            mouse.resetClicks()
            _ = stateMachine.send(.doubleClick)
            return
        }
        pendingClick?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.reactionClicks = self.mouse.recordClick(now: ProcessInfo.processInfo.systemUptime)
            if !self.stateMachine.send(.click) { self.playClickReaction(now: ProcessInfo.processInfo.systemUptime) }
        }
        pendingClick = work
        DispatchQueue.main.asyncAfter(deadline: .now() + PetConfig.doubleClickDelay, execute: work)
    }

    private func rightMouseDown(_ event: NSEvent) {
        pendingClick?.cancel()
        lastInteraction = ProcessInfo.processInfo.systemUptime
        _ = stateMachine.send(.rightClick)
        let menu = NSMenu(title: "菊花梨")
        func add(_ title: String, _ action: Selector, enabled: Bool = true) {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            item.isEnabled = enabled
            menu.addItem(item)
        }
        add("让菊花梨休息", #selector(restPet))
        add("唤醒", #selector(wakePet))
        menu.addItem(.separator())
        add("暂停自动移动", #selector(pauseMovement), enabled: settings.autoMovement)
        add("恢复自动移动", #selector(resumeMovement), enabled: !settings.autoMovement)
        add("始终置顶：\(settings.alwaysOnTop ? "开" : "关")", #selector(toggleTop))
        menu.addItem(.separator())
        add("设置…", #selector(showSettings))
        add("退出桌宠", #selector(quitPet))
        NSMenu.popUpContextMenu(menu, with: event, for: window.spriteView)
    }

    private func applySettings() {
        let size = NSSize(width: PetConfig.baseWidth * CGFloat(settings.scale),
                          height: PetConfig.baseHeight * CGFloat(settings.scale))
        if window.frame.size != size { movement.resize(to: size) }
        window.level = settings.alwaysOnTop ? .floating : .normal
        if !settings.autoMovement && [.walk, .run, .approachMouse].contains(stateMachine.state) {
            _ = stateMachine.send(.movementEnded)
        }
        settingsWindow?.refresh()
    }

    @objc private func screenChanged() { movement.clampToVisibleArea(updateGround: true) }
    @objc func restPet() {
        manualSleepNeedsMouseExit = true
        _ = stateMachine.send(.sleepCommand)
    }
    @objc func wakePet() {
        manualSleepNeedsMouseExit = false
        _ = stateMachine.send(.wake)
    }
    @objc func pauseMovement() { settings.autoMovement = false }
    @objc func resumeMovement() { settings.autoMovement = true }
    @objc func toggleTop() { settings.alwaysOnTop.toggle() }
    @objc func showSettings() {
        if settingsWindow == nil { settingsWindow = SettingsWindowController(settings: settings) }
        settingsWindow?.showWindow(nil)
        settingsWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc func quitPet() { NSApp.terminate(nil) }
}

private extension Bool {
    var sign: CGFloat { self ? 100 : -100 }
}
