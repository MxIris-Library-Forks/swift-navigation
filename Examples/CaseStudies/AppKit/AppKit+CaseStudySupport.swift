#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

// Pieces the AppKit case studies share: the view controller they start from, a form laid out the
// way System Settings lays out its forms, and the windows and view controllers they present.

/// A view controller whose view is a `View` made in code rather than loaded from a nib.
class XiblessViewController<View: NSView>: NSViewController {
  lazy var contentView = View()

  override func loadView() {
    view = contentView
  }

  override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Controls

/// A push button that runs `action` when clicked.
@MainActor
func makeButton(_ title: String, action: @escaping () -> Void) -> NSButton {
  let button = NSButton(title: title, target: nil, action: nil)
  button.addAction { _ in action() }
  return button
}

/// A label for a value that a case study reads from its model, shown on the trailing side of a
/// row.
@MainActor
func makeValueLabel(_ text: String = "") -> NSTextField {
  let label = NSTextField(labelWithString: text)
  label.textColor = .secondaryLabelColor
  label.alignment = .right
  label.lineBreakMode = .byTruncatingTail
  // NB: A long value gives way before the row's title and controls do.
  label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  return label
}

// MARK: - Forms

/// Lays `sections` out the way System Settings lays out a form: one under another, in a column that
/// scrolls and grows no wider than reads well.
@MainActor
func addForm(_ sections: [FormSection], to view: NSView) {
  let column = FormColumnView(sections, spacing: 24)
  column.translatesAutoresizingMaskIntoConstraints = false

  let documentView = FlippedView()
  documentView.translatesAutoresizingMaskIntoConstraints = false
  documentView.addSubview(column)

  let scrollView = NSScrollView()
  scrollView.drawsBackground = false
  scrollView.hasVerticalScroller = true
  scrollView.autohidesScrollers = true
  scrollView.documentView = documentView
  scrollView.translatesAutoresizingMaskIntoConstraints = false
  view.addSubview(scrollView)

  let clipView = scrollView.contentView
  let fillsTheWidth = column.widthAnchor.constraint(equalTo: documentView.widthAnchor, constant: -48)
  fillsTheWidth.priority = .defaultHigh
  NSLayoutConstraint.activate([
    scrollView.topAnchor.constraint(equalTo: view.topAnchor),
    scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    documentView.topAnchor.constraint(equalTo: clipView.topAnchor),
    documentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
    documentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
    column.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 20),
    column.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -24),
    column.centerXAnchor.constraint(equalTo: documentView.centerXAnchor),
    column.widthAnchor.constraint(lessThanOrEqualToConstant: 640),
    fillsTheWidth,
  ])
}

/// A label whose text wraps to the width it is laid out at: a note, a log or a dump of a model.
@MainActor
func makeWrappingLabel(_ text: String = "") -> NSTextField {
  WrappingLabel(wrappingLabelWithString: text)
}

/// A group of rows in a rounded box, with a title above the box and a note below it.
///
/// Hide a section, or a row in it, to take it out of the form; what is left closes up.
final class FormSection: FormColumnView {
  init(_ title: String? = nil, footer: String? = nil, rows: [FormRow]) {
    var arrangedViews: [NSView] = []
    if let title {
      let titleLabel = NSTextField(labelWithString: title)
      titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
      arrangedViews.append(insetHorizontally(titleLabel))
    }
    arrangedViews.append(FormBox(rows: rows))
    if let footer {
      let footerLabel = makeWrappingLabel(footer)
      footerLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
      footerLabel.textColor = .secondaryLabelColor
      arrangedViews.append(insetHorizontally(footerLabel))
    }
    super.init(arrangedViews, spacing: 6)
  }
}

/// A row of a form section: a title on its leading side and controls on its trailing side, or
/// content of its own that spans the row.
final class FormRow: NSView {
  /// The row's title. Empty for a row of content.
  let titleLabel = NSTextField(labelWithString: "")

  /// A row with a title, and an optional line under it, on its leading side, and `accessories`
  /// on its trailing side.
  init(_ title: String, subtitle: String? = nil, accessories: [NSView] = []) {
    super.init(frame: .zero)
    titleLabel.stringValue = title
    titleLabel.lineBreakMode = .byTruncatingTail

    let titleColumn = NSStackView(views: [titleLabel])
    titleColumn.orientation = .vertical
    titleColumn.alignment = .leading
    titleColumn.spacing = 2
    if let subtitle {
      let subtitleLabel = NSTextField(labelWithString: subtitle)
      subtitleLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
      subtitleLabel.textColor = .secondaryLabelColor
      subtitleLabel.lineBreakMode = .byTruncatingTail
      titleColumn.addArrangedSubview(subtitleLabel)
    }
    titleColumn.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleColumn)

    let accessoryRow = NSStackView(views: accessories)
    accessoryRow.orientation = .horizontal
    accessoryRow.alignment = .centerY
    accessoryRow.spacing = 8
    accessoryRow.translatesAutoresizingMaskIntoConstraints = false
    addSubview(accessoryRow)

    // NB: As short as its content allows, but never shorter than a row of buttons.
    let compactHeight = heightAnchor.constraint(equalToConstant: 40)
    compactHeight.priority = .defaultLow
    NSLayoutConstraint.activate([
      titleColumn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      titleColumn.centerYAnchor.constraint(equalTo: centerYAnchor),
      titleColumn.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
      accessoryRow.leadingAnchor.constraint(greaterThanOrEqualTo: titleColumn.trailingAnchor, constant: 16),
      accessoryRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      accessoryRow.centerYAnchor.constraint(equalTo: centerYAnchor),
      accessoryRow.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
      heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
      compactHeight,
    ])
  }

  /// A row that is all `content`, such as a table, a canvas or a log.
  init(content: NSView, insets: NSEdgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)) {
    super.init(frame: .zero)
    pin(content, insets: insets)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

/// A column of views, one under another and each as wide as the column. A hidden view leaves no
/// gap.
///
/// Unlike a vertical `NSStackView`, which only aligns its views, this stretches them to its width.
class FormColumnView: NSView {
  private let arrangedViews: [NSView]
  private let spacing: CGFloat
  private var arrangementConstraints: [NSLayoutConstraint] = []
  private var hiddenObservations: [NSKeyValueObservation] = []

  init(_ arrangedViews: [NSView], spacing: CGFloat) {
    self.arrangedViews = arrangedViews
    self.spacing = spacing
    super.init(frame: .zero)
    for arrangedView in arrangedViews {
      arrangedView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(arrangedView)
    }
    hiddenObservations = arrangedViews.map { arrangedView in
      arrangedView.observe(\.isHidden) { [weak self] _, _ in
        MainActor.assumeIsolated {
          self?.arrange()
        }
      }
    }
    arrange()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// The arranged views that are not hidden, from the top.
  var visibleArrangedViews: [NSView] {
    arrangedViews.filter { !$0.isHidden }
  }

  private func arrange() {
    NSLayoutConstraint.deactivate(arrangementConstraints)
    arrangementConstraints = []
    var previousBottom: NSLayoutYAxisAnchor?
    for arrangedView in arrangedViews {
      arrangementConstraints += [
        arrangedView.leadingAnchor.constraint(equalTo: leadingAnchor),
        arrangedView.trailingAnchor.constraint(equalTo: trailingAnchor),
      ]
      guard !arrangedView.isHidden else {
        // NB: Still placed, so that its layout is not ambiguous, but outside the column's height.
        arrangementConstraints.append(arrangedView.topAnchor.constraint(equalTo: topAnchor))
        continue
      }
      arrangementConstraints.append(
        previousBottom.map { arrangedView.topAnchor.constraint(equalTo: $0, constant: spacing) }
          ?? arrangedView.topAnchor.constraint(equalTo: topAnchor)
      )
      previousBottom = arrangedView.bottomAnchor
    }
    arrangementConstraints.append((previousBottom ?? topAnchor).constraint(equalTo: bottomAnchor))
    NSLayoutConstraint.activate(arrangementConstraints)
    needsDisplay = true
  }
}

/// The rounded box of a form section. It draws the box, and a separator above every visible row
/// but the first.
private final class FormBox: FormColumnView {
  init(rows: [FormRow]) {
    super.init(rows, spacing: 0)
  }

  override func draw(_ dirtyRect: NSRect) {
    let hairline = 1 / (window?.backingScaleFactor ?? 2)
    let box = NSBezierPath(
      roundedRect: bounds.insetBy(dx: hairline / 2, dy: hairline / 2), xRadius: 10, yRadius: 10
    )
    NSColor.quaternarySystemFill.setFill()
    box.fill()
    box.lineWidth = hairline
    NSColor.separatorColor.setStroke()
    box.stroke()

    NSColor.separatorColor.setFill()
    for row in visibleArrangedViews.dropFirst() {
      let rowFrame = convert(row.bounds, from: row)
      let lineY = isFlipped ? rowFrame.minY : rowFrame.maxY - hairline
      NSBezierPath.fill(NSRect(x: bounds.minX + 12, y: lineY, width: bounds.width - 24, height: hairline))
    }
  }

  override func layout() {
    super.layout()
    needsDisplay = true
  }
}

/// A label whose text wraps to the width it is laid out at.
private final class WrappingLabel: NSTextField {
  override func layout() {
    super.layout()
    // NB: The label works its height out from this width, which only layout knows.
    if preferredMaxLayoutWidth != bounds.width {
      preferredMaxLayoutWidth = bounds.width
    }
  }
}

/// A view whose origin is its top-left corner, so that a scroll view shows it from the top.
private final class FlippedView: NSView {
  override var isFlipped: Bool { true }
}

extension NSView {
  /// Adds `subview` and pins its edges to this view's, `insets` in from them.
  fileprivate func pin(_ subview: NSView, insets: NSEdgeInsets) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    addSubview(subview)
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
      subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
      subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
      subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
    ])
  }
}

/// `view` in a container that insets it as far as a row insets its title.
@MainActor
private func insetHorizontally(_ view: NSView) -> NSView {
  let container = NSView()
  container.pin(view, insets: NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
  return container
}

// MARK: - Presented content

/// A titled, closable window showing a message above a row of buttons.
@MainActor
func makeWindow(title: String, message: String, buttons: [NSButton]) -> NSWindow {
  let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 380, height: 150),
    styleMask: [.titled, .closable],
    backing: .buffered,
    defer: false
  )
  window.title = title
  window.isReleasedWhenClosed = false
  window.contentView = makeMessageView(message: message, buttons: buttons)
  window.center()
  return window
}

/// A view controller to present: a message above a row of buttons that ends with Done.
///
/// Done and Return, and Escape in a sheet, run `done` when one is given. Otherwise they dismiss the
/// view controller the way a user would, through `dismiss(_:)`, so the presentation learns about
/// it from the dismissal and clears its state.
class MessageViewController: XiblessViewController<NSView> {
  private let message: String
  private let extraButtons: [NSButton]
  private let done: (() -> Void)?

  init(message: String, extraButtons: [NSButton] = [], done: (() -> Void)? = nil) {
    self.message = message
    self.extraButtons = extraButtons
    self.done = done
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let doneButton = makeButton("Done") { [weak self] in
      self?.finish()
    }
    doneButton.keyEquivalent = "\r"
    view.pin(makeMessageView(message: message, buttons: extraButtons + [doneButton]), insets: NSEdgeInsets())
  }

  /// Escape in a sheet.
  ///
  /// AppKit makes a view controller it presents as a sheet the sheet's delegate, and a window asks
  /// its delegate for `cancel(_:)` when nothing else handles Escape.
  @objc func cancel(_ sender: Any?) {
    finish()
  }

  private func finish() {
    if let done {
      done()
    } else {
      dismiss(nil)
    }
  }
}

/// A message, under an optional bold title, above a row of buttons on the trailing side, the way
/// a dialog lays them out.
@MainActor
func makeMessageView(title: String? = nil, message: String, buttons: [NSButton]) -> NSView {
  let messageLabel = NSTextField(wrappingLabelWithString: message)
  messageLabel.preferredMaxLayoutWidth = 320
  let textColumn = NSStackView(views: [messageLabel])
  textColumn.orientation = .vertical
  textColumn.alignment = .leading
  textColumn.spacing = 6
  if let title {
    let titleLabel = NSTextField(labelWithString: title)
    titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
    textColumn.insertArrangedSubview(titleLabel, at: 0)
  }
  textColumn.translatesAutoresizingMaskIntoConstraints = false
  let buttonRow = NSStackView(views: buttons)
  buttonRow.orientation = .horizontal
  buttonRow.spacing = 8
  buttonRow.translatesAutoresizingMaskIntoConstraints = false

  let container = NSView()
  container.addSubview(textColumn)
  container.addSubview(buttonRow)
  NSLayoutConstraint.activate([
    messageLabel.widthAnchor.constraint(equalToConstant: 320),
    textColumn.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
    textColumn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
    textColumn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
    buttonRow.topAnchor.constraint(equalTo: textColumn.bottomAnchor, constant: 20),
    buttonRow.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
    buttonRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
    buttonRow.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
  ])
  return container
}
#endif
