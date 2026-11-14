#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation

final class NetworkDetailViewController: XiblessViewController<NSView> {
  @UIBindable var model: NetworkDetailModel

  init(model: NetworkDetailModel) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let forgetButton = makeButton("Forget This Network…") { [weak self] in
      self?.model.forgetNetworkButtonTapped()
    }
    let doneButton = makeButton("Done") { [weak self] in
      self?.dismiss(nil)
    }
    doneButton.keyEquivalent = "\r"
    let isConnected = model.network.id == model.selectedNetworkID
    let content = makeMessageView(
      title: model.network.name,
      message: """
        \(isConnected ? "Your Mac is connected to this network." : "Your Mac is not connected to this network.") \
        \(model.network.isSecured ? "It is secured with a password." : "It is an open network.")
        """,
      buttons: [forgetButton, doneButton]
    )
    content.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(content)
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: view.topAnchor),
      content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      content.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    modal(isPresented: $model.forgetAlertIsPresented) { [unowned self] in
      let alert = NSAlert()
      alert.messageText = "Forget Wi-Fi Network “\(model.network.name)”?"
      alert.informativeText = """
      Your Mac and other devices using iCloud Keychain will no longer join this Wi-Fi \
      network.
      """

      alert.addButton(ButtonState<Void>(role: .cancel) { TextState("Cancel") }) { _ in }
      alert.addButton(ButtonState<Void>(role: .destructive) { TextState("Forget") }) { [weak self] _ in
        guard let self else { return }
        model.confirmForgetNetworkButtonTapped()
      }
      return alert
    }
  }

  /// Escape in the sheet, which AppKit asks the sheet's delegate for: this view controller.
  @objc func cancel(_ sender: Any?) {
    dismiss(nil)
  }
}

#Preview {
  NetworkDetailViewController(
    model: NetworkDetailModel(
      network: Network(name: "Blob's WiFi"),
      selectedNetworkID: UUID()
    )
  )
}
#endif
