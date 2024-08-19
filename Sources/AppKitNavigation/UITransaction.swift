#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import SwiftNavigation

extension UITransaction {
    /// Creates a transaction and assigns its animation property.
    ///
    /// - Parameter animation: The animation to perform when the current state changes.
    public init(animation: AppKitAnimation? = nil) {
        self.init()
        appKit.animation = animation
    }

    /// AppKit-specific data associated with the current state change.
    public var appKit: AppKit {
        get { self[AppKitKey.self] }
        set { self[AppKitKey.self] = newValue }
    }

    private enum AppKitKey: UITransactionKey {
        static let defaultValue = AppKit()
    }

    /// AppKit-specific data associated with a ``UITransaction``.
    public struct AppKit: Sendable {
        /// The animation, if any, associated with the current state change.
        public var animation: AppKitAnimation?

        /// A Boolean value that indicates whether views should disable animations.
        public var disablesAnimations = false

        var animationCompletions: [@Sendable (Bool?) -> Void] = []

        /// Adds a completion to run when the animations created with this transaction are all
        /// complete.
        ///
        /// The completion callback will always be fired exactly one time.
        public mutating func addAnimationCompletion(
            _ completion: @escaping @Sendable (Bool?) -> Void
        ) {
            animationCompletions.append(completion)
        }
    }
}

private enum AnimationCompletionsKey: UITransactionKey {
    static let defaultValue: [@Sendable (Bool?) -> Void] = []
}

private enum DisablesAnimationsKey: UITransactionKey {
    static let defaultValue = false
}
#endif
