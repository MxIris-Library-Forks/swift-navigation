#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation
import ConcurrencyExtras

class MinimalObservationViewController: XiblessViewController<NSView>, AppKitCaseStudy {
    let caseStudyTitle = "Minimal observation"
    let readMe = """
    This case study demonstrates how to use the 'observe' tool from the library in order to \
    minimally observe changes to an @Observable model.

    To see this, tap the "Increment" button to see that the view re-renders each time you count \
    up. Then, hide the counter and increment again to see that the view does not re-render, even \
    though the count is changing. This shows that only the state accessed inside the trailing \
    closure of 'observe' causes re-renders.
    """
    @UIBindable var model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        let countLabel = makeValueLabel()
        let viewRenderLabel = makeValueLabel()

        addForm(
            [
                FormSection(
                    "Counter",
                    footer: """
                    Hide the count and increment again: the count keeps changing, but the view no \
                    longer re-renders, because the 'observe' closure stops reading it.
                    """,
                    rows: [
                        FormRow(
                            "Count",
                            accessories: [
                                countLabel,
                                makeButton("Increment") { [weak self] in
                                    self?.model.count += 1
                                },
                            ]
                        ),
                        FormRow("Hide the count", accessories: [NSSwitch(isOn: $model.isCountHidden)]),
                    ]
                ),
                FormSection(
                    "Rendering",
                    rows: [FormRow("Times the view rendered", accessories: [viewRenderLabel])]
                ),
            ],
            to: view
        )

        let viewRenderCount = LockIsolated(0)
        observe { [unowned self] in
            viewRenderCount.withValue { $0 += 1 }

            if !model.isCountHidden {
                // NB: We do not access 'model.count' when the count is hidden, and therefore its mutations
                //     will not cause a re-render of the view.
                countLabel.stringValue = model.count.description
            }
            countLabel.isHidden = model.isCountHidden
            viewRenderLabel.stringValue = viewRenderCount.value.description
        }
    }

    @Observable
    class Model {
        var count = 0
        var isCountHidden = false
    }
}

#Preview {
    MinimalObservationViewController()
}

#endif
