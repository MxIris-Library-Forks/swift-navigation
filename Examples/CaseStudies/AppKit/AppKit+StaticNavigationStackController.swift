#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation
import AppKitPlus

final class StaticNavigationStackController: NavigationStackController, AppKitCaseStudy {
  let caseStudyTitle = "Statically typed path"
  let readMe = """
  This case study demonstrates 'NavigationStackController', an AppKit replacement for SwiftUI's \
  'NavigationStack'. It is built on AppKitPlus's 'NSNavigationController', so it needs the \
  package's 'AppKitPlus' trait, which this project turns on.

  Each screen pushes a new element onto the path with the 'push' trait, and dismisses itself \
  with the 'dismiss' trait. Going back with the back button, ⌘↑ or a swipe updates the path too.
  """
  private var model: Model!

  convenience init(model: Model) {
    @UIBindable var model = model
    self.init(path: $model.path) {
      StaticRootViewController(model: model)
    }
    navigationDestination(for: Model.Path.self) { feature in
      StaticFeatureViewController(feature: feature)
    }
    self.model = model
  }

  @Observable
  class Model {
    var path: [Path] = []

    enum Path: Hashable, CaseIterable {
      case feature1
      case feature2
      case feature3

      var title: String {
        switch self {
        case .feature1: "Feature 1"
        case .feature2: "Feature 2"
        case .feature3: "Feature 3"
        }
      }
    }
  }
}

/// The bottom of the stack: a button for each feature, and one that pushes all three at once.
private final class StaticRootViewController: XiblessViewController<NSView> {
  let model: StaticNavigationStackController.Model

  init(model: StaticNavigationStackController.Model) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
    title = "Static path"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let pathLabel = makeValueLabel()
    let featureRows = StaticNavigationStackController.Model.Path.allCases.map { feature in
      FormRow(
        feature.title,
        accessories: [
          makeButton("Push") { [weak self] in
            self?.traitCollection.push(value: feature)
          },
        ]
      )
    }
    let allFeaturesRow = FormRow(
      "All three",
      subtitle: "Feature 1 → 2 → 3",
      accessories: [
        makeButton("Push") { [weak self] in
          self?.model.path.append(contentsOf: [.feature1, .feature2, .feature3])
        },
      ]
    )

    addForm(
      [
        FormSection("Push", rows: featureRows + [allFeaturesRow]),
        FormSection(
          "Model",
          footer: "Going back with the back button, ⌘↑ or a swipe shortens the path too.",
          rows: [FormRow("Path", accessories: [pathLabel])]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      pathLabel.stringValue = model.path.isEmpty ? "Empty" : model.path.map(\.title).joined(separator: " → ")
    }
  }
}

/// A screen on the stack: it can push any feature, or dismiss itself.
private final class StaticFeatureViewController: XiblessViewController<NSView> {
  let feature: StaticNavigationStackController.Model.Path

  init(feature: StaticNavigationStackController.Model.Path) {
    self.feature = feature
    super.init(nibName: nil, bundle: nil)
    title = feature.title
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let featureRows = StaticNavigationStackController.Model.Path.allCases.map { feature in
      FormRow(
        feature.title,
        accessories: [
          makeButton("Push") { [weak self] in
            self?.traitCollection.push(value: feature)
          },
        ]
      )
    }

    addForm(
      [
        FormSection("Push", rows: featureRows),
        FormSection(
          rows: [
            FormRow(
              "This screen",
              accessories: [
                makeButton("Dismiss") { [weak self] in
                  self?.traitCollection.dismiss()
                },
              ]
            ),
          ]
        ),
      ],
      to: view
    )
  }
}

#Preview {
  StaticNavigationStackController(model: StaticNavigationStackController.Model())
}
#endif
