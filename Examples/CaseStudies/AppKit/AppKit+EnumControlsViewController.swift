#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation

class EnumControlsViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyNavigationTitle = "Enum controls"
  let caseStudyTitle = "Concise enum controls"
  let readMe = """
  This case study demonstrates how to drive form controls from bindings to enum state. In this \
  example, a single `Status` enum holds two cases:

  • An integer quantity for when an item is in stock, which can drive a stepper.
  • A Boolean for whether an item is on back order when it is _not_ in stock, which can drive a \
  switch.

  This library provides tools to chain deeper into a binding's case by applying the \
  `@CasePathable` macro.
  """

  @CasePathable
  enum Status {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
  }

  @UIBinding var status: Status = .inStock(quantity: 100)

  override func viewDidLoad() {
    super.viewDidLoad()

    let statusLabel = makeValueLabel()
    let outOfStockButton = makeButton("Out of stock") { [weak self] in
      self?.status = .outOfStock(isOnBackOrder: false)
    }
    let backInStockButton = makeButton("Back in stock!") { [weak self] in
      self?.status = .inStock(quantity: 100)
    }
    let quantityLabel = makeValueLabel()
    let quantityStepper = NSStepper()
    quantityStepper.maxValue = .infinity
    let quantityRow = FormRow("Quantity", accessories: [quantityLabel, quantityStepper])
    let isOnBackOrderSwitch = NSSwitch()
    let isOnBackOrderRow = FormRow("On back order", accessories: [isOnBackOrderSwitch])

    addForm(
      [
        FormSection(
          "Item",
          footer: "The stepper and the switch bind into the cases of a single status enum.",
          rows: [
            FormRow("Status", accessories: [statusLabel, outOfStockButton, backInStockButton]),
            quantityRow,
            isOnBackOrderRow,
          ]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      let isInStock = status.is(\.inStock)
      statusLabel.stringValue = isInStock ? "In stock" : "Out of stock"
      outOfStockButton.isHidden = !isInStock
      backInStockButton.isHidden = isInStock
      quantityRow.isHidden = !isInStock
      isOnBackOrderRow.isHidden = isInStock

      switch status {
      case .inStock:
        if let quantity = $status.inStock {
          quantityLabel.stringValue = quantity.wrappedValue.description
          quantityStepper.bind(value: quantity.asDouble)
        }

      case .outOfStock:
        if let isOnBackOrder = $status.outOfStock {
          isOnBackOrderSwitch.bind(isOn: isOnBackOrder)
        }
      }
    }
  }
}

@available(macOS 14.0, *)
#Preview {
  EnumControlsViewController()
}

extension Int {
  fileprivate var asDouble: Double {
    get { Double(self) }
    set { self = Int(newValue) }
  }
}

#endif
