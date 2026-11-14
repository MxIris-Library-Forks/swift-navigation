#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class BasicsNavigationViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Basics"
  let readMe = """
  This case study demonstrates how to perform every major form of navigation in AppKit (modal \
  panels, sheets) by driving navigation off of optional and boolean state.
  """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let openPanelStatusLabel = makeValueLabel()
    let chosenFileLabel = makeValueLabel()
    let numberSheetStatusLabel = makeValueLabel()
    let sheetStatusLabel = makeValueLabel()

    addForm(
      [
        FormSection(
          "Optional state",
          footer: "Setting an optional presents content for its value, and clearing it dismisses the content.",
          rows: [
            FormRow(
              "Open panel",
              accessories: [
                openPanelStatusLabel,
                makeButton("Show") { [weak self] in
                  self?.model.openPanelMessage = "Choose a file to show its name."
                },
              ]
            ),
            FormRow("Chosen file", accessories: [chosenFileLabel]),
            FormRow(
              "Sheet with a number",
              subtitle: "Closes itself after 3 seconds",
              accessories: [
                numberSheetStatusLabel,
                makeButton("Show") { [weak self] in
                  let number = Int.random(in: 1 ... 1_000)
                  self?.model.sheet = number
                  DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    // NB: Only the sheet this click presented: it may have been closed, and
                    //     another one presented, in the meantime.
                    if self?.model.sheet == number {
                      self?.model.sheet = nil
                    }
                  }
                },
              ]
            ),
          ]
        ),
        FormSection(
          "Boolean state",
          footer: "The sheet's Done button sets the Boolean back to false.",
          rows: [
            FormRow(
              "Sheet",
              accessories: [
                sheetStatusLabel,
                makeButton("Show") { [weak self] in
                  self?.model.isSheetPresented = true
                },
              ]
            ),
          ]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      openPanelStatusLabel.stringValue = model.openPanelMessage != nil ? "Shown" : "Not shown"
      chosenFileLabel.stringValue = model.url?.lastPathComponent ?? "None"
      numberSheetStatusLabel.stringValue = model.sheet.map { "Showing \($0)" } ?? "Not shown"
      sheetStatusLabel.stringValue = model.isSheetPresented ? "Shown" : "Not shown"
    }

    modal(item: $model.openPanelMessage, id: \.self) { [unowned self] message in
      let openPanel = NSOpenPanel(url: $model.url)
      openPanel.message = message
      return openPanel
    }

    present(item: $model.sheet, id: \.self, style: .sheet) { [unowned self] number in
      MessageViewController(message: "The number is \(number).") { [weak self] in
        self?.model.sheet = nil
      }
    }

    present(isPresented: $model.isSheetPresented, style: .sheet) { [unowned self] in
      MessageViewController(message: "Hello!") { [weak self] in
        self?.model.isSheetPresented = false
      }
    }
  }

  @Observable
  class Model {
    var openPanelMessage: String?
    var isSheetPresented = false
    var sheet: Int?
    var url: URL?
  }
}

#Preview {
  BasicsNavigationViewController()
}
#endif
