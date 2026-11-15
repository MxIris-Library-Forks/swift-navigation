# Draft - 把 macOS 下限提到 14

- **状态**: In Progress
- **创建日期**: 2026-11-15
- **最后更新**: 2026-11-15
- **实现分支**: `raise-macos-minimum`

## 摘要

AppKitPlus 的 `main` 已把最低系统提到 macOS 14（AppKitPlus 提案 0117），下一个 AppKitPlus-Release 会在清单里声明 `.macOS(.v14)`。这个 fork 带 AppKitPlus trait 的两份清单仍声明 macOS 12：到那时打开 trait，即使 App 的部署目标更高，SwiftPM 也会因为 fork 自己声明的下限直接报错。另外，部署目标低于 13.3 时，Swift 对改过运行时名的协议做 `as?` 或声明采纳都会悄悄失效（swiftlang/swift#94329）。栈导航内部采纳 `NSNavigationControllerDelegate` 的 `PathDelegate` 正受此影响，只是 AppKitPlus 调用 delegate 前只看它实现了哪些方法、不检查协议，所以还没出问题。这一批不等 AppKitPlus 发版，先把这两份清单的 macOS 下限提到 14。

## 方案

- `Package.swift`（Xcode 27 用）与 `Package@swift-6.2.swift`（Xcode 26.x 用）的 `.macOS(.v12)` 改成 `.macOS(.v14)`；iOS、tvOS、watchOS 的下限不变。
- 使用指南 `StackNavigationWithAppKitPlus.md` 里 trait 的系统要求随之改成 macOS 14。
- 对使用方是破坏性变更：部署目标低于 macOS 14 的 App，以及声明的 macOS 下限低于 14、又依赖这个 fork 的包，升级后都编不过。2026-11-15 核对过依赖这个 fork 的几个 App（XCOrganizer、PrivateSymbols、SymbolViewer、MacKedUpdater、ReverseEngineeringToolbox），部署目标最低是 14.3，都不受影响。

没有询问就采用的假设：

- `Package@swift-6.0.swift` 与 `Package@swift-6.1.swift` 不动，仍是 macOS 10.15：它们没有 AppKitPlus trait，只给 Xcode 16 用；自 0012 起 AppKitNavigation 只能用 Xcode 27 编，这两份只影响其余几个库。
- 代码里因此变得多余的 macOS 版本判断（`@available(macOS 14, *)`、`#available(…macOS 12…)` 之类）不删：多数在与上游共用的文件里，改了会增加合并上游时的冲突。
- 下限到 14 后，为 macOS 编译时多出 5 条弃用警告，这一批不改：SwiftUI 的 `onChange(of:perform:)` 4 处（`Bind.swift` 两处、`Alert.swift`、`ConfirmationDialog.swift`，都与上游一字不差），Perception 的 `withPerceptionTracking` 1 处（`Observe.swift`）。前者换成新 API 要按平台分开写，因为 iOS 的下限仍是 15；改了会让这些文件与上游分叉。
- 不为 `PathDelegate` 的协议采纳单写测试：目前没有哪项可观察的行为受它影响，单测协议采纳等于测编译器本身；下限不低于 13.3，问题的前提就不存在了。

## 后续项

- AppKitPlus-Release 发出要求 macOS 14 的版本后，再把示例锁定的版本升上去；`Package.swift` 里 AppKitPlus-Release 的版本下限要不要跟着提，到时再定。
- 那 5 条弃用警告先留着，等上游改用新 API 或提高下限时再跟进。
- fork 发版时，版本号要体现最低系统提高这一破坏性变更。
- AppKitNavigation 自己的几处 `@available(macOS 14, *)` 可以删掉；`Perception` trait 在 macOS 上可能不再必需，可以评估。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-15 | Created as Draft | AppKitPlus 下一版要求 macOS 14，fork 两份带 trait 的清单仍是 12，届时打开 trait 会报错；部署目标低于 13.3 还会让栈导航 delegate 的协议采纳在运行时失效 |
| 2026-11-15 | 用户批准，开始实现 | 用户知道这对所有使用方都是破坏性变更，决定现在就提，不等 AppKitPlus 发版 |
| 2026-11-15 | 多出的 5 条弃用警告先不改，交给用户定 | 改前改后各从零编一次对比：多出的只有这 5 条，都在与上游共用的文件里；改不改是在「编译干净」与「少和上游分叉」之间取舍 |
| 2026-11-15 | 实现完成，待用户看过后收尾 | 全量 `swift test` 只有 `ButtonStateTests.testAsyncAnimationWarning` 失败，与改前相同，是 macOS 27.2 上早就存在的上游问题；打开 AppKitPlus trait 的 AppKit 测试全部通过（XCTest 94 个，Swift Testing 78 个）；`CaseStudies` 的 macOS 版编译通过。文档判断：使用指南里的系统要求已同步，不需要另写实现说明，没有新术语 |
| 2026-11-15 | 5 条弃用警告先留着 | 用户选定：不改与上游共用的文件，合并上游时不增加冲突 |
