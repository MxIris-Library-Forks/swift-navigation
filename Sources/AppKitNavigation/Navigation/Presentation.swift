#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  public import AppKit

  extension NSViewController {
    /// How a view controller presents another one.
    public enum TransitionStyle {
      /// Attached to the presenting view controller's window as a sheet.
      case sheet
      /// In a window of its own, run modally.
      case modalWindow
      /// In a popover pointing at a rectangle in a view.
      ///
      /// - Parameters:
      ///   - rect: The rectangle, in `view`'s coordinates, that the popover points at.
      ///   - view: The view the popover is anchored to.
      ///   - preferredEdge: The edge of `rect` the popover prefers to show from.
      ///   - behavior: Whether the popover closes when the user interacts with something else.
      case popover(rect: NSRect, view: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)
      /// By an animator of your own.
      case custom(any NSViewControllerPresentationAnimator)
    }

    /// Presents a view controller while a binding to a Boolean value you provide is true.
    ///
    /// Like SwiftUI's `sheet` and `popover` view modifiers, but for AppKit. Setting the binding to
    /// `false` dismisses the view controller. When the user dismisses it — a Cancel button wired to
    /// `dismissController(_:)`, a transient popover closing — the binding is set to `false`. The
    /// view controller is presented once this view controller's view is in a window on screen; a
    /// modal window also goes up while that window is minimized.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the view
    ///     controller.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present.
    /// - Returns: A token that stops following the binding once cancelled. A view controller that
    ///   is presented then stays until the user dismisses it.
    @discardableResult
    public func present(
      isPresented: UIBinding<Bool>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping () -> NSViewController
    ) -> ObserveToken {
      present(item: isPresented.toOptionalUnit, style: style, onDismiss: onDismiss) { _ in
        content()
      }
    }

    /// Presents a view controller while a binding to an optional item holds a value.
    ///
    /// The view controller is presented as with
    /// ``present(isPresented:style:onDismiss:content:)``. If the item's identity changes, the view
    /// controller is dismissed, and once it has left the screen, one for the new item is
    /// presented.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, the value is passed to `content`. When the user dismisses the view controller,
    ///     the binding is set to `nil`.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller while a binding to an optional item holds a value, passing the
    /// content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func present<Item: Identifiable>(
      item: UIBinding<Item?>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      present(item: item, id: \.id, style: style, onDismiss: onDismiss, content: content)
    }

    /// Presents a view controller while a binding to an optional item holds a value, telling items
    /// apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, the value is passed to `content`. When the user dismisses the view controller,
    ///     the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     dismissed, and once it has left the screen, one for the new item is presented.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func present<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (Item) -> NSViewController
    ) -> ObserveToken {
      present(item: item, id: id, style: style, onDismiss: onDismiss) {
        content($0.wrappedValue)
      }
    }

    /// Presents a view controller while a binding to an optional item holds a value, telling items
    /// apart by the identifier at a key path and passing the content a binding to the item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     dismissed, and once it has left the screen, one for the new item is presented.
    ///   - style: How to present it.
    ///   - onDismiss: The closure to execute once the view controller has been dismissed and has
    ///     left the screen.
    ///   - content: A closure that returns the view controller to present for the item.
    /// - Returns: A token that stops following the binding once cancelled.
    @_disfavoredOverload
    @discardableResult
    public func present<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      style: TransitionStyle,
      onDismiss: (() -> Void)? = nil,
      content: @escaping (UIBinding<Item>) -> NSViewController
    ) -> ObserveToken {
      bindPresentation(
        ViewControllerPresentationStyle(presenter: self, transition: .style(style)),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: onDismiss,
        content: content
      )
    }

    /// Presents a view controller in a way of your own while a binding to a Boolean value you
    /// provide is true.
    ///
    /// This helper powers ``present(isPresented:style:onDismiss:content:)``, and can define custom
    /// transitions. A view controller presented through AppKit counts as having left the screen
    /// once AppKit no longer lists it among this view controller's presented view controllers and
    /// its window is off screen. One that never went through AppKit's presentation, such as a
    /// child added with `addChild(_:)`, counts as having left the screen as soon as `dismiss`
    /// returns.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the view
    ///     controller.
    ///   - content: A closure that returns the view controller to present.
    ///   - present: The closure to execute to present the view controller.
    ///   - dismiss: The closure to execute to dismiss the view controller.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func destination(
      isPresented: UIBinding<Bool>,
      content: @escaping () -> NSViewController,
      present: @escaping (NSViewController, UITransaction) -> Void,
      dismiss: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      destination(
        item: isPresented.toOptionalUnit,
        content: { _ in content() },
        present: present,
        dismiss: dismiss
      )
    }

    /// Presents a view controller in a way of your own while a binding to an optional item holds a
    /// value.
    ///
    /// The view controller stays the same while the binding holds any value, whatever its
    /// identity. To replace it when the item's identity changes, use
    /// ``destination(item:id:content:present:dismiss:)``.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - content: A closure that returns the view controller to present.
    ///   - present: The closure to execute to present the view controller.
    ///   - dismiss: The closure to execute to dismiss the view controller.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func destination<Item>(
      item: UIBinding<Item?>,
      content: @escaping (UIBinding<Item>) -> NSViewController,
      present: @escaping (NSViewController, UITransaction) -> Void,
      dismiss: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      bindPresentation(
        ViewControllerPresentationStyle(
          presenter: self, transition: .custom(present: present, dismiss: dismiss)
        ),
        item: item,
        id: { _ in nil },
        onDismiss: nil,
        content: content
      )
    }

    /// Presents a view controller in a way of your own while a binding to an optional item holds a
    /// value, telling items apart by the identifier at a key path.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the view controller. While it holds
    ///     a value, a binding to the value is passed to `content`. When the user dismisses the view
    ///     controller, the binding is set to `nil`.
    ///   - id: The key path to the item's identifier. When it changes, the view controller is
    ///     dismissed, and once it has left the screen, one for the new item is presented.
    ///   - content: A closure that returns the view controller to present.
    ///   - present: The closure to execute to present the view controller.
    ///   - dismiss: The closure to execute to dismiss the view controller.
    /// - Returns: A token that stops following the binding once cancelled.
    @discardableResult
    public func destination<Item, Identifier: Hashable>(
      item: UIBinding<Item?>,
      id: KeyPath<Item, Identifier>,
      content: @escaping (UIBinding<Item>) -> NSViewController,
      present: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void,
      dismiss: @escaping (
        _ child: NSViewController,
        _ transaction: UITransaction
      ) -> Void
    ) -> ObserveToken {
      bindPresentation(
        ViewControllerPresentationStyle(
          presenter: self, transition: .custom(present: present, dismiss: dismiss)
        ),
        item: item,
        id: { $0[keyPath: id] },
        onDismiss: nil,
        content: content
      )
    }

    fileprivate func present(_ viewController: NSViewController, as style: TransitionStyle) {
      switch style {
      case .sheet:
        presentAsSheet(viewController)
      case .modalWindow:
        presentAsModalWindow(viewController)
      case let .popover(rect, view, preferredEdge, behavior):
        present(
          viewController,
          asPopoverRelativeTo: rect,
          of: view,
          preferredEdge: preferredEdge,
          behavior: behavior
        )
      case let .custom(animator):
        present(viewController, animator: animator)
      }
    }
  }

  /// Presents a view controller from another one, through AppKit's view controller presentation or
  /// in a way of the caller's own.
  @MainActor
  private struct ViewControllerPresentationStyle: PresentationStyle {
    enum Transition {
      case style(NSViewController.TransitionStyle)
      case custom(
        present: (NSViewController, UITransaction) -> Void,
        dismiss: (NSViewController, UITransaction) -> Void
      )
    }

    weak var presenter: NSViewController?
    let transition: Transition

    func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
      // NB: A sheet or a popover attaches to the presenter's window, so the presenter has to be on
      //     screen, the way 'NSWindow.sheet' and 'NSView.popover' wait for their anchors. A modal
      //     window has a window of its own, and a transition of the caller's own is up to the
      //     caller, so for those the presenter's window may be on screen or in the Dock. A
      //     presenter that has gone away counts as ready, so that 'begin' finds out.
      let isReady: @MainActor (NSViewController) -> Bool
      switch transition {
      case .style(.sheet), .style(.popover):
        isReady = { $0.appKitNavigationIsViewOnScreen }
      case .style(.modalWindow), .style(.custom), .custom:
        isReady = { $0.appKitNavigationIsViewOnScreenOrMinimized }
      }
      return RunLoopWait.until(
        { [weak presenter] in presenter.map(isReady) ?? true },
        then: body
      )
    }

    func begin(
      _ child: NSViewController,
      transaction: UITransaction,
      didEnd: @escaping @MainActor () -> Void
    ) {
      guard let presenter else {
        didEnd()
        return
      }
      // NB: AppKit tells no one but the presenter that it dismissed a view controller, and the user
      //     can dismiss one without going through the binding: with a Cancel button wired to
      //     'dismissController:', or by closing a transient popover. So the view controller is
      //     watched instead. Once AppKit has listed it among the presenter's presented view
      //     controllers, it counts as ended when it has left that list and its window is off
      //     screen. The watch starts before presenting, so that it also runs inside any modal loop
      //     presenting starts.
      let record = PresentationRecord(didEnd: didEnd)
      child.appKitNavigationPresentationRecord = record
      _ = RunLoopWait.until(
        { [weak presenter, weak child] in
          guard !record.hasEnded, let child else { return true }
          let isPresented = presenter?.presentedViewControllers?.contains(child) == true
          if isPresented {
            record.hasBeenPresented = true
          }
          return record.hasBeenPresented && !isPresented
            && (!child.isViewLoaded || child.view.window?.isVisible != true)
        },
        then: { record.end() }
      )
      switch transition {
      case let .style(style):
        presenter.present(child, as: style)
      case let .custom(present, _):
        withUITransaction(transaction) {
          present(child, transaction)
        }
      }
      // NB: Noted right away as well, since the watch only looks when the run loop is about to
      //     wait: the user can dismiss the view controller before that.
      if presenter.presentedViewControllers?.contains(child) == true {
        record.hasBeenPresented = true
      }
    }

    func end(_ child: NSViewController, transaction: UITransaction) {
      switch transition {
      case .style:
        // NB: Only through this weak reference: 'presentingViewController' is not one, and is not
        //     safe to read while the presenter is being deallocated.
        if let presenter, presenter.presentedViewControllers?.contains(child) == true {
          presenter.dismiss(child)
          return
        }
      case let .custom(_, dismiss):
        withUITransaction(transaction) {
          dismiss(child, transaction)
        }
        if presenter?.presentedViewControllers?.contains(child) == true {
          return
        }
      }
      // NB: One that went through AppKit's presentation ends once the watch sees it off screen.
      //     Any other one, and one whose presenter has gone away, ends now.
      guard let record = child.appKitNavigationPresentationRecord else { return }
      if record.hasBeenPresented, presenter != nil {
        return
      }
      record.end()
    }
  }

  /// What a view controller presented by ``ViewControllerPresentationStyle`` reports its end to.
  @MainActor
  private final class PresentationRecord {
    /// Whether AppKit has listed the view controller among its presenter's presented ones.
    var hasBeenPresented = false
    private var didEnd: (@MainActor () -> Void)?

    init(didEnd: @escaping @MainActor () -> Void) {
      self.didEnd = didEnd
    }

    var hasEnded: Bool {
      didEnd == nil
    }

    /// Reports that the view controller has ended, unless that has been reported already.
    func end() {
      guard let didEnd else { return }
      self.didEnd = nil
      didEnd()
    }
  }

  extension NSViewController {
    fileprivate var appKitNavigationPresentationRecord: PresentationRecord? {
      get {
        objc_getAssociatedObject(self, presentationRecordKey) as? PresentationRecord
      }
      set {
        objc_setAssociatedObject(
          self, presentationRecordKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
      }
    }
  }

  @MainActor
  private let presentationRecordKey = malloc(1)!
#endif
