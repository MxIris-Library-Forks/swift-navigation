#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class ConciseEnumNavigationViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyNavigationTitle = "Enum navigation"
  let caseStudyTitle = "Concise enum navigation"
  let readMe = """
  This case study demonstrates how to navigate to multiple destinations from a single optional \
  enum.

  This allows you to be very concise with your domain modeling by having a single enum \
  describe all the possible destinations you can navigate to. In the case of this demo, we have \
  four cases in the enum, which means there are exactly 5 possible states, including the case \
  where none are active.

  If you were to instead model this domain with 4 optionals (or booleans), then you would have \
  16 possible states, of which only 5 are valid. That can leak complexity into your domain \
  because you can never be sure of exactly what is presented at a given time.
  """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let alertStatusLabel = makeValueLabel()
    let numberSheetStatusLabel = makeValueLabel()
    let sheetStatusLabel = makeValueLabel()

    addForm(
      [
        FormSection(
          "Destination",
          footer: "One optional enum holds whichever of these is up, so at most one can be presented at a time.",
          rows: [
            FormRow(
              "Alert",
              accessories: [
                alertStatusLabel,
                makeButton("Show") { [weak self] in
                  self?.model.destination = .alert("Hello!")
                },
              ]
            ),
            FormRow(
              "Sheet with a number",
              accessories: [
                numberSheetStatusLabel,
                makeButton("Show") { [weak self] in
                  self?.model.destination = .sheet(.random(in: 1 ... 1_000))
                },
              ]
            ),
            FormRow(
              "Sheet without a payload",
              accessories: [
                sheetStatusLabel,
                makeButton("Show") { [weak self] in
                  self?.model.destination = .sheetWithoutPayload
                },
              ]
            ),
          ]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      alertStatusLabel.stringValue = model.destination?.alert != nil ? "Shown" : "Not shown"
      numberSheetStatusLabel.stringValue = model.destination?.sheet.map { "Showing \($0)" } ?? "Not shown"
      sheetStatusLabel.stringValue = model.destination?.sheetWithoutPayload != nil ? "Shown" : "Not shown"
    }

    modal(item: $model.destination.alert, id: \.self) { message in
      let alert = NSAlert()
      alert.messageText = "This is an alert"
      alert.informativeText = message
      alert.addButton(withTitle: "OK")
      return alert
    }
    present(item: $model.destination.sheet, id: \.self, style: .sheet) { [unowned self] number in
      MessageViewController(message: "The number is \(number).") { [weak self] in
        self?.model.destination = nil
      }
    }
    present(isPresented: UIBinding($model.destination.sheetWithoutPayload), style: .sheet) { [unowned self] in
      MessageViewController(message: "Hello!") { [weak self] in
        self?.model.destination = nil
      }
    }
  }

  @Observable
  class Model {
    var destination: Destination?
    @CasePathable
    @dynamicMemberLookup
    enum Destination {
      case alert(String)
      case drillDown(Int)
      case sheet(Int)
      case sheetWithoutPayload
    }
  }
}

#Preview {
  ConciseEnumNavigationViewController()
}
#endif
