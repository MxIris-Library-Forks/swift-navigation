#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKitNavigation
import SwiftUI

/// The case studies app on the Mac: a sidebar that lists every case study, beside the one that is
/// chosen.
struct SidebarRootView: View {
  @State private var catalog = CaseStudyCatalog()
  @SceneStorage("SidebarRootView.selection") private var selection: CaseStudyPage.ID?

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        ForEach(catalog.sections) { section in
          Section(section.title) {
            ForEach(section.pages) { page in
              Label(page.title, systemImage: page.systemImage)
            }
          }
        }
      }
      .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 340)
    } detail: {
      if let page = selection.flatMap(catalog.page(id:)) {
        CaseStudyPageView(page: page)
          // NB: Each case study gets a page of its own, rather than one page whose content changes.
          .id(page.id)
      } else {
        ContentUnavailableView(
          "No Case Study Selected",
          systemImage: "sidebar.left",
          description: Text("Choose one in the sidebar to try it.")
        )
      }
    }
  }
}

/// A case study beside the sidebar, with its read-me behind the toolbar's info button.
private struct CaseStudyPageView: View {
  let page: CaseStudyPage
  @State private var isAboutPresented = false

  var body: some View {
    NavigationStack {
      page.content
        .navigationTitle(page.navigationTitle)
        .navigationSubtitle(page.framework)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button {
              isAboutPresented.toggle()
            } label: {
              Label("About", systemImage: "info.circle")
            }
            .help("About this case study")
            .popover(isPresented: $isAboutPresented, arrowEdge: .bottom) {
              Text(template: page.readMe)
                .frame(width: 360, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(20)
            }
          }
        }
    }
  }
}

/// Every case study the sidebar lists, made once for each window.
///
/// The AppKit case studies keep their state while another one is shown, since the same view
/// controller comes back when its case study is chosen again.
@MainActor
final class CaseStudyCatalog {
  let sections = CaseStudySection.swiftUISections() + CaseStudySection.appKitSections()

  func page(id: CaseStudyPage.ID) -> CaseStudyPage? {
    for section in sections {
      if let page = section.pages.first(where: { $0.id == id }) {
        return page
      }
    }
    return nil
  }
}

/// A group of case studies in the sidebar.
struct CaseStudySection: Identifiable {
  let title: String
  let pages: [CaseStudyPage]

  var id: String { title }
}

/// A case study in the sidebar, and what shows beside it once it is chosen.
struct CaseStudyPage: Identifiable {
  let id: String
  let title: String
  let navigationTitle: String
  let framework: String
  let readMe: String
  let systemImage: String
  let content: AnyView
}

extension CaseStudyPage {
  @MainActor
  init(_ caseStudy: some SwiftUICaseStudy, systemImage: String) {
    self.init(
      id: String(describing: type(of: caseStudy)),
      title: caseStudy.caseStudyTitle,
      navigationTitle: caseStudy.caseStudyNavigationTitle,
      framework: "SwiftUI",
      readMe: caseStudy.readMe,
      systemImage: systemImage,
      // NB: Grouped, like System Settings and the AppKit case studies, rather than in columns.
      content: AnyView(CaseStudyView { caseStudy }.formStyle(.grouped))
    )
  }

  @MainActor
  init(_ caseStudy: some AppKitCaseStudy, systemImage: String) {
    self.init(
      id: String(describing: type(of: caseStudy)),
      title: caseStudy.caseStudyTitle,
      navigationTitle: caseStudy.caseStudyNavigationTitle,
      framework: "AppKit",
      readMe: caseStudy.readMe,
      systemImage: systemImage,
      content: AnyView(NSViewControllerRepresenting { caseStudy })
    )
  }
}

extension CaseStudySection {
  /// The SwiftUI case studies, in the groups `SwiftUICaseStudiesView` lists them in.
  @MainActor
  static func swiftUISections() -> [Self] {
    [
      Self(
        title: "SwiftUI · Navigation",
        pages: [
          CaseStudyPage(OptionalNavigation(), systemImage: "rectangle.on.rectangle.angled"),
          CaseStudyPage(EnumNavigation(), systemImage: "list.bullet.rectangle"),
          CaseStudyPage(AlertDialogState(), systemImage: "exclamationmark.bubble"),
        ]
      ),
      Self(
        title: "SwiftUI · Binding helpers",
        pages: [
          CaseStudyPage(SynchronizedBindings(), systemImage: "arrow.triangle.2.circlepath"),
          CaseStudyPage(EnumControls(), systemImage: "switch.2"),
        ]
      ),
    ]
  }
}

#Preview {
  SidebarRootView()
}
#endif
