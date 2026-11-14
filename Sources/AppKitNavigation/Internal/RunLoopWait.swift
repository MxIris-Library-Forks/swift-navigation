#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  import AppKit

  /// Waits for something on screen to change — a window to come on screen, a view to get into a
  /// window, a sheet to finish leaving the screen — by checking each time the main run loop is
  /// about to wait, and each time a run of it ends.
  ///
  /// Notifications are not reliable for this. A window brought on screen in a process that is not
  /// the active app — a test runner, for one — posts no occlusion, key or main window notification
  /// at all, a view has none for getting into a window, and a sheet's completion handler runs
  /// before the sheet has left the screen. The check costs a closure call per turn of the run
  /// loop, and only while something is waiting.
  ///
  /// The check comes after everything else the run loop does at those points, Core Animation's
  /// commit included, so that it sees the screen as that turn leaves it. AppKit fetches every
  /// event in a run of its own, so a change is seen before the next event is handled: a user who
  /// dismisses content and at once asks for it again, for one, does not have the second request
  /// undone by the first.
  @MainActor
  enum RunLoopWait {
    /// Calls `body` once `condition` holds — right away when it already does — and returns a
    /// closure that cancels the wait.
    static func until(
      _ condition: @escaping @MainActor () -> Bool,
      then body: @escaping @MainActor () -> Void
    ) -> @MainActor () -> Void {
      if condition() {
        body()
        return {}
      }
      // NB: In the common modes, so that the wait goes on inside modal loops and while the mouse
      //     is tracking.
      nonisolated(unsafe) let observer = CFRunLoopObserverCreateWithHandler(
        nil, CFRunLoopActivity([.beforeWaiting, .exit]).rawValue, true, CFIndex.max
      ) { observer, _ in
        MainActor._assumeIsolated {
          guard condition() else { return }
          CFRunLoopObserverInvalidate(observer)
          body()
        }
      }
      CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
      return {
        CFRunLoopObserverInvalidate(observer)
      }
    }
  }

  extension NSViewController {
    /// Whether the view controller's view is in a window that is on screen.
    ///
    /// Never loads the view: one that is not loaded yet is not on screen.
    var appKitNavigationIsViewOnScreen: Bool {
      isViewLoaded && view.window?.isVisible == true
    }
  }

#endif
