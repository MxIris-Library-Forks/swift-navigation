#if canImport(AppKit) && !targetEnvironment(macCatalyst)

public import AppKit

extension NSSavePanel {
    /// Creates a save panel that writes the URL the user chooses to a binding.
    ///
    /// The binding is written when the panel, shown with
    /// ``ObjectiveC/NSObject/modal(isPresented:onDismiss:content:)`` or
    /// ``AppKit/NSWindow/sheet(isPresented:onDismiss:content:)``, ends with the user confirming
    /// their choice, before the presentation's `onDismiss` runs. Cancelling leaves the binding as it
    /// is. A panel the app runs itself, with `begin(completionHandler:)` or `runModal()`, does not
    /// write it: the app learns what the user chose from the panel's response instead.
    ///
    /// - Parameter url: A binding to write the chosen URL to.
    public convenience init(url: UIBinding<URL?>) {
        self.init()
        bind(url: url)
    }

    /// Writes the URL the user chooses in this panel to a binding.
    ///
    /// The binding is written as described in ``init(url:)``. Binding again replaces the binding
    /// given before.
    ///
    /// - Parameter binding: A binding to write the chosen URL to.
    /// - Returns: A token that stops writing to the binding once cancelled.
    @discardableResult
    public func bind(url binding: UIBinding<URL?>) -> ObserveToken {
        // NB: The previous binding's token has to be cancelled before the new binding is stored.
        //     Left to be released when its entry is replaced below, it would clear the binding it no
        //     longer owns.
        unbindURL()
        let confirmedChoiceBindings = appKitNavigationConfirmedChoiceBindings
        confirmedChoiceBindings.url = binding
        let observationToken = ObserveToken { [weak confirmedChoiceBindings] in
            MainActor._assumeIsolated {
                confirmedChoiceBindings?.url = nil
            }
        }
        observationTokens[\NSSavePanel.url] = observationToken
        return observationToken
    }

    /// Stops writing the URL the user chooses to the binding given to ``bind(url:)``.
    public func unbindURL() {
        observationTokens[\NSSavePanel.url]?.cancel()
        observationTokens[\NSSavePanel.url] = nil
    }
}

extension NSOpenPanel {
    /// Creates an open panel that writes the URLs the user chooses to a binding.
    ///
    /// The binding is written when the panel, shown with
    /// ``ObjectiveC/NSObject/modal(isPresented:onDismiss:content:)`` or
    /// ``AppKit/NSWindow/sheet(isPresented:onDismiss:content:)``, ends with the user confirming
    /// their choice, before the presentation's `onDismiss` runs. Cancelling leaves the binding as it
    /// is. A panel the app runs itself, with `begin(completionHandler:)` or `runModal()`, does not
    /// write it: the app learns what the user chose from the panel's response instead.
    ///
    /// - Parameter urls: A binding to write the chosen URLs to.
    public convenience init(urls: UIBinding<[URL]>) {
        self.init()
        bind(urls: urls)
    }

    /// Writes the URLs the user chooses in this panel to a binding.
    ///
    /// The binding is written as described in ``init(urls:)``. Binding again replaces the binding
    /// given before.
    ///
    /// - Parameter binding: A binding to write the chosen URLs to.
    /// - Returns: A token that stops writing to the binding once cancelled.
    @discardableResult
    public func bind(urls binding: UIBinding<[URL]>) -> ObserveToken {
        // NB: See 'NSSavePanel.bind(url:)'.
        unbindURLs()
        let confirmedChoiceBindings = appKitNavigationConfirmedChoiceBindings
        confirmedChoiceBindings.urls = binding
        let observationToken = ObserveToken { [weak confirmedChoiceBindings] in
            MainActor._assumeIsolated {
                confirmedChoiceBindings?.urls = nil
            }
        }
        observationTokens[\NSOpenPanel.urls] = observationToken
        return observationToken
    }

    /// Stops writing the URLs the user chooses to the binding given to ``bind(urls:)``.
    public func unbindURLs() {
        observationTokens[\NSOpenPanel.urls]?.cancel()
        observationTokens[\NSOpenPanel.urls] = nil
    }
}

extension NSSavePanel {
    /// Writes what the user chose to the bindings given to ``bind(url:)`` and
    /// ``NSOpenPanel/bind(urls:)``, once the panel has ended with the user confirming it.
    ///
    /// AppKit reports the choice only through the panel's response, which only whoever runs the
    /// panel sees: the library's sheet and modal presentation call this.
    func appKitNavigationWriteConfirmedChoice() {
        guard
            let confirmedChoiceBindings = objc_getAssociatedObject(self, confirmedChoiceBindingsKey)
                as? ConfirmedChoiceBindings
        else { return }
        confirmedChoiceBindings.url?.wrappedValue = url
        if let openPanel = self as? NSOpenPanel {
            confirmedChoiceBindings.urls?.wrappedValue = openPanel.urls
        }
    }

    /// The bindings this panel writes the user's choice to, made on first use.
    fileprivate var appKitNavigationConfirmedChoiceBindings: ConfirmedChoiceBindings {
        if let confirmedChoiceBindings = objc_getAssociatedObject(self, confirmedChoiceBindingsKey)
            as? ConfirmedChoiceBindings
        {
            return confirmedChoiceBindings
        }
        let confirmedChoiceBindings = ConfirmedChoiceBindings()
        objc_setAssociatedObject(
            self, confirmedChoiceBindingsKey, confirmedChoiceBindings,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return confirmedChoiceBindings
    }
}

/// The bindings a save or open panel writes the user's choice to.
@MainActor
private final class ConfirmedChoiceBindings {
    var url: UIBinding<URL?>?
    var urls: UIBinding<[URL]>?
}

@MainActor
private let confirmedChoiceBindingsKey = malloc(1)!

#endif
