#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class DismissalViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Dismissal"
  let readMe = """
  Presented content ends in one of three ways: you dismiss it, its state is cleared, or its state \
  switches to another item. Each way calls 'onDismiss' exactly once, after the content has left \
  the screen. When you dismiss it yourself, the state is cleared before 'onDismiss' runs. When the \
  item changes, the next item's sheet only comes up once the previous one has gone.

  The sheet's buttons try all three; the log lists each 'onDismiss' call with what the state held \
  at the time.
  """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let fruitLabel = makeValueLabel()
    let logLabel = makeWrappingLabel()
    logLabel.textColor = .secondaryLabelColor

    addForm(
      [
        FormSection(
          "Sheet",
          footer: "Done dismisses the sheet the way a user would; its other buttons change the state instead.",
          rows: [
            FormRow(
              "Fruit",
              accessories: [
                fruitLabel,
                makeButton("Present") { [weak self] in
                  self?.model.fruit = .apple
                },
              ]
            ),
          ]
        ),
        FormSection("onDismiss log", rows: [FormRow(content: logLabel)]),
      ],
      to: view
    )

    observe { [unowned self] in
      fruitLabel.stringValue = model.fruit.map { $0.name.prefix(1).uppercased() + $0.name.dropFirst() } ?? "None"
      logLabel.stringValue = model.log.isEmpty ? "Nothing dismissed yet." : model.log.joined(separator: "\n")
    }

    present(item: $model.fruit, style: .sheet, onDismiss: { [weak self] in
      guard let self else { return }
      model.record("onDismiss ran; the state holds \(model.fruit?.name ?? "nothing")")
    }) { [unowned self] fruit in
      MessageViewController(
        message: """
          This sheet shows \(fruit.name). Done dismisses it the way a user would; the other \
          buttons change its state instead.
          """,
        extraButtons: [
          makeButton("Clear the state") { [weak self] in
            self?.model.record("Cleared the state")
            self?.model.fruit = nil
          },
          makeButton("Switch to \(fruit.next.name)") { [weak self] in
            self?.model.record("Switched the state to \(fruit.next.name)")
            self?.model.fruit = fruit.next
          },
        ]
      )
    }
  }

  @Observable
  class Model {
    var fruit: Fruit?
    var log: [String] = []

    func record(_ event: String) {
      log = Array((log + [event]).suffix(10))
    }
  }

  enum Fruit: Int, Identifiable {
    case apple
    case banana
    case cherry

    var id: Self { self }

    var name: String {
      switch self {
      case .apple: "an apple"
      case .banana: "a banana"
      case .cherry: "a cherry"
      }
    }

    var next: Self {
      Self(rawValue: rawValue + 1) ?? .apple
    }
  }
}

#Preview {
  DismissalViewController()
}
#endif
