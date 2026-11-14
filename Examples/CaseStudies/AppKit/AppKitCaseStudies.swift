#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKitNavigation

extension CaseStudySection {
  /// The AppKit case studies, grouped by what they show.
  @MainActor
  static func appKitSections() -> [Self] {
    [
      Self(
        title: "AppKit · Observation",
        pages: [
          CaseStudyPage(MinimalObservationViewController(), systemImage: "eye"),
          CaseStudyPage(AnimationsViewController(), systemImage: "sparkles"),
        ]
      ),
      Self(
        title: "AppKit · Bindings",
        pages: [
          CaseStudyPage(NSControlBindingsViewController(), systemImage: "slider.horizontal.3"),
          CaseStudyPage(EnumControlsViewController(), systemImage: "switch.2"),
          CaseStudyPage(FocusViewController(), systemImage: "scope"),
          CaseStudyPage(OptionBindingsViewController(), systemImage: "checklist"),
          CaseStudyPage(TableSelectionViewController(), systemImage: "tablecells"),
        ]
      ),
      Self(
        title: "AppKit · Optional navigation",
        pages: [
          CaseStudyPage(BasicsNavigationViewController(), systemImage: "rectangle.on.rectangle"),
          CaseStudyPage(ConciseEnumNavigationViewController(), systemImage: "list.bullet.rectangle"),
        ]
      ),
      Self(
        title: "AppKit · Presentation",
        pages: [
          CaseStudyPage(PresentationGalleryViewController(), systemImage: "macwindow.on.rectangle"),
          CaseStudyPage(NestedModalViewController(), systemImage: "square.stack.3d.up"),
          CaseStudyPage(DismissalViewController(), systemImage: "xmark.rectangle"),
        ]
      ),
      Self(
        title: "AppKit · Stack navigation",
        pages: [
          CaseStudyPage(
            StaticNavigationStackController(model: StaticNavigationStackController.Model()),
            systemImage: "rectangle.stack"
          ),
          CaseStudyPage(
            ErasedNavigationStackController(model: ErasedNavigationStackController.Model()),
            systemImage: "square.stack"
          ),
          // TODO: state restoration
        ]
      ),
      Self(
        title: "AppKit · Advanced",
        pages: [
          // TODO: Deep link
          CaseStudyPage(
            WiFiSettingsViewController(model: WiFiSettingsModel(foundNetworks: .mocks)),
            systemImage: "wifi"
          ),
        ]
      ),
    ]
  }
}
#endif
