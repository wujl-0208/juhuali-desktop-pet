import Foundation

enum PetState: String {
    case idle, lookMouse, approachMouse, walk, run, jump
    case clickReaction, doubleClickReaction, rightClickReaction
    case dragged, drowsy, sleep, wakeUp
}

enum PetEvent {
    case mouseMiddle, mouseNear, mouseFar
    case randomWalk, randomRun, randomJump, randomLook
    case sleepTimeout, sleepCommand, wake
    case click, doubleClick, rightClick
    case dragStart, dragEnd, animationEnded, landed, movementEnded
}

/// Only this class decides which state may interrupt another state.
final class PetStateMachine {
    private(set) var state: PetState = .idle
    var onChange: ((PetState, PetState) -> Void)?

    @discardableResult
    func send(_ event: PetEvent) -> Bool {
        let next: PetState?
        switch event {
        case .dragStart:
            next = .dragged
        case .dragEnd:
            next = state == .dragged ? .idle : nil
        case .click:
            next = state == .dragged ? nil : .clickReaction
        case .doubleClick:
            next = state == .dragged ? nil : .doubleClickReaction
        case .rightClick:
            next = state == .dragged ? nil : .rightClickReaction
        case .wake:
            next = [.sleep, .drowsy].contains(state) ? .wakeUp : nil
        case .sleepCommand:
            next = state == .dragged ? nil : .drowsy
        case .sleepTimeout:
            next = state == .idle ? .drowsy : nil
        case .mouseMiddle:
            next = [.idle, .walk, .run].contains(state) ? .lookMouse : nil
        case .mouseNear:
            next = [.idle, .lookMouse, .walk, .run].contains(state) ? .approachMouse : nil
        case .mouseFar:
            next = [.lookMouse, .approachMouse].contains(state) ? .idle : nil
        case .randomWalk:
            next = state == .idle ? .walk : nil
        case .randomRun:
            next = state == .idle ? .run : nil
        case .randomJump:
            next = state == .idle ? .jump : nil
        case .randomLook:
            next = state == .idle ? .lookMouse : nil
        case .landed:
            next = [.jump, .doubleClickReaction].contains(state) ? .idle : nil
        case .movementEnded:
            next = [.walk, .run, .approachMouse, .lookMouse].contains(state) ? .idle : nil
        case .animationEnded:
            switch state {
            case .drowsy: next = .sleep
            case .wakeUp, .clickReaction, .rightClickReaction: next = .idle
            default: next = nil
            }
        }
        guard let next, next != state else { return false }
        let previous = state
        state = next
        onChange?(previous, next)
        return true
    }
}
