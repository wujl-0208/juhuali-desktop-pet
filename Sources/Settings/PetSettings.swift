import Foundation

final class PetSettings {
    static let shared = PetSettings()
    private let defaults = UserDefaults.standard
    var onChange: (() -> Void)?

    private init() {}

    var scale: Double {
        get { defaults.object(forKey: "scale") as? Double ?? 1.0 }
        set { defaults.set(min(max(newValue, PetConfig.minScale), PetConfig.maxScale), forKey: "scale"); onChange?() }
    }
    var autoMovement: Bool {
        get { defaults.object(forKey: "autoMovement") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoMovement"); onChange?() }
    }
    var mouseFollowing: Bool {
        get { defaults.object(forKey: "mouseFollowing") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "mouseFollowing"); onChange?() }
    }
    var proximityInteraction: Bool {
        get { defaults.object(forKey: "proximityInteraction") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "proximityInteraction"); onChange?() }
    }
    var alwaysOnTop: Bool {
        get { defaults.object(forKey: "alwaysOnTop") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "alwaysOnTop"); onChange?() }
    }
    var animationSpeed: Double {
        get { defaults.object(forKey: "animationSpeed") as? Double ?? 1.0 }
        set { defaults.set(min(max(newValue, 0.5), 1.6), forKey: "animationSpeed"); onChange?() }
    }
    var soundEnabled: Bool {
        get { defaults.object(forKey: "soundEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "soundEnabled"); onChange?() }
    }
}
