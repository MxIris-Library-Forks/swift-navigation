#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class NestedModalViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Nested modals"
  let readMe = """
  A modal can present another modal on top of itself. Here a settings window runs modally, and \
  its Reset button asks for confirmation with an alert that runs on top of the window. Ending the \
  alert returns to the settings window, which is still running.

  The settings window can also be closed from its state while the alert is up — try "Close in 3 \
  seconds" and then "Reset…". AppKit only stops the innermost modal, so the window waits until \
  the alert has ended, and then closes.
  """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let settingsWindowLabel = makeValueLabel()
    let confirmationAlertLabel = makeValueLabel()
    let resetCountLabel = makeValueLabel()

    addForm(
      [
        FormSection(
          "Modals",
          footer: "Try “Close in 3 seconds” and then “Reset…”: the window waits for the alert to end before it closes.",
          rows: [
            FormRow(
              "Settings window",
              accessories: [
                settingsWindowLabel,
                makeButton("Open") { [weak self] in
                  self?.model.isSettingsPresented = true
                },
              ]
            ),
            FormRow("Confirmation alert", accessories: [confirmationAlertLabel]),
            FormRow("Resets", accessories: [resetCountLabel]),
          ]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      settingsWindowLabel.stringValue = model.isSettingsPresented ? "Open" : "Closed"
      confirmationAlertLabel.stringValue = model.resetConfirmation != nil ? "Open" : "Closed"
      resetCountLabel.stringValue = model.resetCount.description
    }

    modal(isPresented: $model.isSettingsPresented) { [unowned self] in
      makeWindow(
        title: "Settings",
        message: "This window runs modally. Reset asks for confirmation with an alert on top of it.",
        buttons: [
          makeButton("Reset…") { [weak self] in
            self?.model.resetConfirmation = .reset
          },
          makeButton("Close in 3 seconds") { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              self?.model.isSettingsPresented = false
            }
          },
          makeButton("Close") { [weak self] in
            self?.model.isSettingsPresented = false
          },
        ]
      )
    }

    modal(item: $model.resetConfirmation) { [unowned self] alert in
      NSAlert(state: alert) { [weak self] action in
        if action == .reset {
          self?.model.resetCount += 1
        }
      }
    }
  }

  @Observable
  class Model {
    var isSettingsPresented = false
    var resetConfirmation: AlertState<ConfirmationAction>?
    var resetCount = 0

    enum ConfirmationAction {
      case reset
    }
  }
}

extension AlertState where Action == NestedModalViewController.Model.ConfirmationAction {
  static var reset: Self {
    AlertState {
      TextState("Reset all settings?")
    } actions: {
      ButtonState(role: .destructive, action: .reset) {
        TextState("Reset")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    } message: {
      TextState("The settings go back to how they were when the app was installed.")
    }
  }
}

#Preview {
  NestedModalViewController()
}
#endif
