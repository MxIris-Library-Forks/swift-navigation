#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation
import SwiftUI

class AnimationsViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Animations"
  let readMe = """
  This case study demonstrates how to drive animations from state in an AppKit application. To \
  animate a model mutation, wrap the mutation in 'withAppKitAnimation'. To animate changes to a \
  binding, use the '.animation()' method on 'UIBinding'.

  Click or drag in the gray area to move the circle with a spring, flip the switch to scale it, \
  and cycle through its colors with the button.
  """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let canvasView = CanvasView()
    canvasView.clipsToBounds = true
    canvasView.heightAnchor.constraint(equalToConstant: 320).isActive = true
    canvasView.onPointer = { [weak self] location in
      withAppKitAnimation(Self.springAnimation) {
        self?.model.position = location
      }
    }
    let circleView = NSView()
    circleView.wantsLayer = true
    canvasView.addSubview(circleView)

    addForm(
      [
        FormSection(
          "Circle",
          rows: [
            FormRow(
              "Scaled up",
              accessories: [NSSwitch(isOn: $model.isScaled.animation(Self.springAnimation))]
            ),
            FormRow(
              "Color",
              accessories: [
                makeButton("Cycle colors") { [weak self] in
                  guard let self else { return }
                  Task { await self.model.cycleColors() }
                },
              ]
            ),
          ]
        ),
        FormSection(
          "Canvas",
          footer: "Click or drag in the canvas to move the circle with a spring.",
          rows: [FormRow(content: canvasView, insets: NSEdgeInsets())]
        ),
      ],
      to: view
    )

    observe { [unowned self] in
      // NB: 'NSView' has no 'transform' to scale with, so the circle grows by its frame instead.
      let diameter: CGFloat = model.isScaled ? 200 : 100
      circleView.frame = NSRect(
        x: model.position.x - diameter / 2,
        y: model.position.y - diameter / 2,
        width: diameter,
        height: diameter
      )
      circleView.layer?.cornerRadius = diameter / 2
      circleView.layer?.backgroundColor = model.color.cgColor
    }
  }

  /// A spring where the system has one, which is macOS 15 and later.
  private static var springAnimation: AppKitAnimation {
    if #available(macOS 15, *) {
      AppKitAnimation(.spring(duration: 0.4, bounce: 0.6))
    } else {
      .easeInOut(duration: 0.4)
    }
  }

  @MainActor
  @Observable
  class Model {
    var position = CGPoint(x: 150, y: 160)
    var isScaled = false
    var color = NSColor.systemBlue

    func cycleColors() async {
      let colors: [NSColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemPurple, .systemBlue]
      for color in colors {
        withAppKitAnimation { self.color = color }
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }
}

/// The area the circle moves in. It reports where it is clicked and dragged.
private final class CanvasView: NSView {
  var onPointer: (@MainActor (CGPoint) -> Void)?

  override func mouseDown(with event: NSEvent) {
    report(event)
  }

  override func mouseDragged(with event: NSEvent) {
    report(event)
  }

  private func report(_ event: NSEvent) {
    let location = convert(event.locationInWindow, from: nil)
    guard bounds.contains(location) else { return }
    onPointer?(location)
  }
}

#Preview {
  AnimationsViewController()
}
#endif
