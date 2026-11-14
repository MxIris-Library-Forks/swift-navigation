#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// A save or open panel shown with `sheet` or `modal` writes what the user confirms to its
  /// binding, and leaves the binding as it is when the user cancels.
  final class PanelBindingTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    @MainActor
    func testConfirmingASavePanelSheetWritesTheChosenURL() {
      let host = makeHost()
      let confirmedURL = Self.makeUniqueURL()
      @UIBinding var isPresented = false
      @UIBinding var chosenURL: URL?
      let savePanel = NSSavePanel(url: $chosenURL)
      host.window.sheet(isPresented: $isPresented) { savePanel }

      isPresented = true
      XCTAssertTrue(
        waitUntil(timeout: 8) { host.window.attachedSheet === savePanel },
        "The save panel never appeared as a sheet"
      )
      guard confirm(savePanel, choosing: [confirmedURL]) else { return }

      XCTAssertTrue(
        waitUntil(timeout: 5) { !isPresented }, "Confirming the panel did not end the sheet"
      )
      XCTAssertEqual(chosenURL, confirmedURL)
    }

    @MainActor
    func testCancellingASavePanelSheetLeavesTheBindingAsItIs() {
      let host = makeHost()
      let earlierURL = Self.makeUniqueURL()
      @UIBinding var isPresented = false
      @UIBinding var chosenURL: URL? = earlierURL
      let savePanel = NSSavePanel(url: $chosenURL)
      host.window.sheet(isPresented: $isPresented) { savePanel }

      isPresented = true
      XCTAssertTrue(
        waitUntil(timeout: 8) { host.window.attachedSheet === savePanel },
        "The save panel never appeared as a sheet"
      )
      // What the panel's Cancel button does.
      savePanel.cancel(nil)

      XCTAssertTrue(
        waitUntil(timeout: 5) { !isPresented }, "Cancelling the panel did not end the sheet"
      )
      XCTAssertEqual(chosenURL, earlierURL)
    }

    /// What a reused panel does: the same panel is bound to the next model.
    @MainActor
    func testRebindingASavePanelWritesOnlyToTheNewBinding() {
      let host = makeHost()
      let confirmedURL = Self.makeUniqueURL()
      @UIBinding var isPresented = false
      @UIBinding var firstURL: URL?
      @UIBinding var secondURL: URL?
      let savePanel = NSSavePanel(url: $firstURL)
      savePanel.bind(url: $secondURL)
      host.window.sheet(isPresented: $isPresented) { savePanel }

      isPresented = true
      XCTAssertTrue(
        waitUntil(timeout: 8) { host.window.attachedSheet === savePanel },
        "The save panel never appeared as a sheet"
      )
      guard confirm(savePanel, choosing: [confirmedURL]) else { return }

      XCTAssertTrue(
        waitUntil(timeout: 5) { !isPresented }, "Confirming the panel did not end the sheet"
      )
      XCTAssertNil(firstURL, "The previous binding was written")
      XCTAssertEqual(secondURL, confirmedURL)
    }

    @MainActor
    func testRebindingAnOpenPanelWritesOnlyToTheNewBinding() {
      let host = makeHost()
      let confirmedURLs = [Self.makeUniqueURL(), Self.makeUniqueURL()]
      @UIBinding var isPresented = false
      @UIBinding var firstURLs: [URL] = []
      @UIBinding var secondURLs: [URL] = []
      let openPanel = NSOpenPanel(urls: $firstURLs)
      openPanel.bind(urls: $secondURLs)
      openPanel.allowsMultipleSelection = true
      host.window.sheet(isPresented: $isPresented) { openPanel }

      isPresented = true
      XCTAssertTrue(
        waitUntil(timeout: 8) { host.window.attachedSheet === openPanel },
        "The open panel never appeared as a sheet"
      )
      guard confirm(openPanel, choosing: confirmedURLs) else { return }

      XCTAssertTrue(
        waitUntil(timeout: 5) { !isPresented }, "Confirming the panel did not end the sheet"
      )
      XCTAssertEqual(firstURLs, [], "The previous binding was written")
      XCTAssertEqual(secondURLs, confirmedURLs)
    }

    @MainActor
    func testConfirmingAModalSavePanelWritesTheChosenURL() {
      let host = NSObject()
      let confirmedURL = Self.makeUniqueURL()
      @UIBinding var isPresented = false
      @UIBinding var chosenURL: URL?
      let savePanel = NSSavePanel(url: $chosenURL)
      host.modal(isPresented: $isPresented) { savePanel }
      abortModalLoops(after: 8)

      let start = Date()
      perform(after: 1) {
        self.confirm(savePanel, choosing: [confirmedURL])
      }
      isPresented = true

      XCTAssertTrue(waitUntil(timeout: 7) { !isPresented }, "Confirming the panel did not end it")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 6,
        "The panel only ended when the safety timer aborted it"
      )
      XCTAssertEqual(chosenURL, confirmedURL)
    }

    /// Ends `panel` the way the panel service does once the user has confirmed `urls`, and returns
    /// whether it could.
    ///
    /// The panel runs in another process, and the copy in this one implements none of its
    /// buttons' actions but Cancel's: `ok(_:)` raises "not implemented". The service reports the
    /// user's choice through a private method instead, so the tests confirm through it, after
    /// checking it is there: messaging a selector the panel no longer has would crash the whole
    /// test run. It takes the URLs even from a save panel, and raises when they are missing.
    @MainActor
    @discardableResult
    private func confirm(_ panel: NSSavePanel, choosing urls: [URL]) -> Bool {
      guard panel.responds(to: NSSelectorFromString("completeWithReturnCode:url:urls:")) else {
        XCTFail("NSSavePanel no longer has 'completeWithReturnCode:url:urls:'")
        return false
      }
      (panel as AnyObject).complete(
        returnCode: NSApplication.ModalResponse.OK.rawValue, url: urls.first, urls: urls
      )
      return true
    }

    /// A file URL nothing else uses. Nothing is created at it.
    private static func makeUniqueURL() -> URL {
      FileManager.default.temporaryDirectory.appending(
        path: "AppKitNavigationTests-\(UUID().uuidString).txt"
      )
    }
  }

  /// The private method through which the panel service reports the user's choice to a panel.
  @objc private protocol PanelCompletion {
    @objc(completeWithReturnCode:url:urls:)
    func complete(returnCode: Int, url: URL?, urls: [URL]?)
  }
#endif
