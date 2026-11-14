#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation

class FocusViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Focus"
  let readMe = """
  This case study demonstrates how to handle `UITextField` focus in a state-driven manner. The \
  focus in the UI is kept in sync with the focus value held in an observable model so that \
  changes in one are immediately reflected in the other.
  """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let usernameTextField = NSTextField(text: $model.username)
    usernameTextField.bind(focus: $model.focus, equals: .username)
    let emailTextField = NSTextField(text: $model.email)
    emailTextField.bind(focus: $model.focus, equals: .email)
    let passwordTextField = NSSecureTextField(text: $model.password)
    passwordTextField.bind(focus: $model.focus, equals: .password)
    let bioTextField = NSTextField(text: $model.bio)
    bioTextField.bind(focus: $model.focus, equals: .bio)
    for textField in [usernameTextField, emailTextField, passwordTextField, bioTextField] {
      textField.bezelStyle = .roundedBezel
      textField.widthAnchor.constraint(equalToConstant: 240).isActive = true
    }
    let fieldRows: [(FormRow, Model.Focus)] = [
      (FormRow("Username", accessories: [usernameTextField]), .username),
      (FormRow("Email", accessories: [emailTextField]), .email),
      (FormRow("Password", accessories: [passwordTextField]), .password),
      (FormRow("Bio", accessories: [bioTextField]), .bio),
    ]
    let currentFocusLabel = makeValueLabel()

    addForm(
      [
        FormSection(
          "Account",
          footer: "The title of the field that the model says has focus is tinted.",
          rows: fieldRows.map(\.0)
        ),
        FormSection(
          "Focus",
          footer: "The model and the window keep the focus in step: click into a field, or move the focus from here.",
          rows: [
            FormRow("Current focus", accessories: [currentFocusLabel]),
            FormRow(
              "Move the focus to",
              accessories: [
                makeButton("Username") { [weak self] in
                  self?.model.focus = .username
                },
                makeButton("Email") { [weak self] in
                  self?.model.focus = .email
                },
                makeButton("Password") { [weak self] in
                  self?.model.focus = .password
                },
                makeButton("Bio") { [weak self] in
                  self?.model.focus = .bio
                },
              ]
            ),
            FormRow(
              "Resign first responder",
              accessories: [
                makeButton("Resign") { [weak self] in
                  self?.view.window?.makeFirstResponder(nil)
                },
              ]
            ),
          ]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      currentFocusLabel.stringValue = model.focus?.rawValue.capitalized ?? "None"
      for (row, focus) in fieldRows {
        row.titleLabel.textColor = model.focus == focus ? .controlAccentColor : .labelColor
      }
    }
  }

  @Observable
  class Model {
    var bio = ""
    var email = ""
    var focus: Focus?
    var password = ""
    var username = ""
    enum Focus: String {
      case bio
      case email
      case password
      case username
    }
  }
}

#Preview {
  FocusViewController()
}

#endif
