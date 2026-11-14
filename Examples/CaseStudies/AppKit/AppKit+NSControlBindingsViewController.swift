#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class NSControlBindingsViewController: XiblessViewController<NSView>, AppKitCaseStudy {
    let caseStudyTitle = "NSControl bindings"
    let readMe = """
    This demonstrates how to use the library's `@UIBinding` and `@UIBindable` property wrappers \
    to bind an observable model to various `NSControl`s. For the most part it works exactly \
    as it does in SwiftUI. Just use `$model` to construct an object that can derive bindings, \
    and then use simple dot-syntax to decide which field you want to derive a binding for.
    """
    @UIBindable var model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        let colorWell = NSColorWell(color: $model.color)
        let datePicker = NSDatePicker(date: $model.date)
        let segmentControl = NSSegmentedControl(labels: Model.Segment.allCases.map { "\($0)" }, trackingMode: .selectOne, target: nil, action: nil)
        segmentControl.bind(selectedSegment: $model.segment)
        let slider = NSSlider(value: $model.sliderValue)
        slider.widthAnchor.constraint(equalToConstant: 180).isActive = true
        let stepperValueLabel = makeValueLabel()
        let stepper = NSStepper(value: $model.stepperValue)
        let `switch` = NSSwitch(isOn: $model.isOn)
        let textField = NSTextField(text: $model.text)
        textField.bind(focus: $model.focus, equals: .text)
        textField.bind(selection: $model.textSelection)
        textField.bezelStyle = .roundedBezel
        textField.widthAnchor.constraint(equalToConstant: 200).isActive = true
        let modelLabel = makeWrappingLabel()
        modelLabel.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        modelLabel.textColor = .secondaryLabelColor

        addForm(
            [
                FormSection(
                    "Controls",
                    rows: [
                        FormRow("Color well", accessories: [colorWell]),
                        FormRow("Date picker", accessories: [datePicker]),
                        FormRow("Segmented control", accessories: [segmentControl]),
                        FormRow("Slider", accessories: [slider]),
                        FormRow("Stepper", accessories: [stepperValueLabel, stepper]),
                        FormRow("Switch", accessories: [`switch`]),
                        FormRow("Text field", accessories: [textField]),
                    ]
                ),
                FormSection(
                    "Model",
                    footer: "Each control writes to the model through its binding, and the model writes back to the control.",
                    rows: [FormRow(content: modelLabel)]
                ),
            ],
            to: view
        )

        observe { [unowned self] in
            stepperValueLabel.stringValue = model.stepperValue.formatted()

            let textSelection = model.textSelection.map {
                self.model.text.range(for: $0.range)
            }

            modelLabel.stringValue = """
            MyModel(
              color: \(model.color.description),
              date: \(model.date),
              focus: \(model.focus.map(String.init(describing:)) ?? "nil"),
              isOn: \(model.isOn),
              segment: \(model.segment),
              sliderValue: \(model.sliderValue),
              stepperValue: \(model.stepperValue),
              text: \(model.text.debugDescription),
              textSelection: \(textSelection.map(String.init(describing:)) ?? "nil")
            )
            """
        }
    }

    @MainActor
    @Observable
    final class Model: HashableObject {
        var color: NSColor = .systemBlue
        var date = Date()
        var focus: Focus?
        var isOn = false
        var segment = Segment.columnA
        var sliderValue: Float = 0.5
        var stepperValue: Double = 5
        var text = "Blob"
        var textSelection: AppKitTextSelection?

        enum Focus: Hashable {
            case attributedText
            case text
        }

        enum Segment: Int, CaseIterable {
            case columnA
            case columnB
        }
    }
}

extension String {
    fileprivate func range(for range: Range<String.Index>) -> Range<Int> {
        distance(
            from: startIndex, to: range.lowerBound
        ) ..< distance(from: startIndex, to: range.upperBound)
    }
}

#Preview(traits: .fixedLayout(width: 500, height: 800)) {
    NSControlBindingsViewController()
}

#endif
