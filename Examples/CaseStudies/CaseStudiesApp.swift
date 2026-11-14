import SwiftUI

@main
struct CaseStudiesApp: App {
  var body: some Scene {
    WindowGroup {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
      SidebarRootView()
      #else
      RootView()
      #endif
    }
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    .defaultSize(width: 1100, height: 760)
    #endif
  }
}
