# Draft - 去掉 AppKitNavigationShim：不再交换系统方法

- **状态**: In Progress
- **创建日期**: 2026-11-14
- **最后更新**: 2026-11-14
- **实现分支**: `appkit-remove-shim`

## 摘要

`AppKitNavigationShim` 是一个 Objective-C target，在 `+load` 里交换了五个系统方法：`NSViewController` 的 `viewDidAppear`、`viewDidDisappear`、`dismissViewController:`，以及 `NSSavePanel` 的私有方法 `setFinalURL:`、`setFinalURLs:`；另外为 macOS 27 以前的 SDK 重新声明了 `NSControl` 的多 target-action API。交换方法改变的是 App 里每一个视图控制器和存取面板的行为，依赖的私有方法被系统改名时还会静默失效。这一批把它整个删掉：前三个交换改用库里已有的 `RunLoopWait`（主 run loop 每次要休眠前检查一次条件），存取面板的 URL 绑定改由库的 `sheet` / `modal` 在面板以「确定」结束时写回，NSControl 的重复声明直接删除——项目已统一使用 Xcode 27，它的 SDK 自带这组 API。

## 方案

| shim 做的事 | 用途 | 替代 |
|---|---|---|
| 交换 `viewDidAppear`，记下「视图出现过」并执行排队的闭包 | `present`、`destination` 等到发起者的视图出现后再弹出；`navigationDestination` 等到它出现后再 push | `RunLoopWait` 等条件成立：弹出要等发起者的视图在一个可见窗口里，`NSWindow.sheet` 与 `NSView.popover` 早就这么判断；push 要等发起者所在的导航控制器的视图在可见窗口里 |
| 交换 `dismissViewController:` 与 `viewDidDisappear`，在被关闭的视图控制器消失时回调 | 用户自己关掉弹出的视图控制器（接到 `dismissController:` 的取消按钮、transient popover 收起）时把绑定写回 | 弹出之前就开始用 `RunLoopWait` 盯着：视图控制器出现在发起者的 `presentedViewControllers` 里之后，等它离开这个列表、窗口也不再可见，就算结束。`navigationDestination` 早就用同样的办法判断 pop |
| 交换私有的 `setFinalURL:` / `setFinalURLs:` | `NSSavePanel(url:)`、`NSOpenPanel(urls:)` 把用户确认的 URL 写回绑定 | `WindowBackedContent` 给存取面板的实现里，`beginSheetModal` 回调收到的、或 `runModal` 返回的结果是 `.OK` 时写回 |
| 重新声明 `NSControlEvents` 与 `addTarget(_:action:for:)` | 旧 SDK 下也能编过 `TargetActionProxy` | 删除；`TargetActionProxy` 里为旧 SDK 导入 AppKitPlus 的变通一起删 |

落地步骤（每步各自构建、测试通过）：

1. **弹出生命周期**（已完成）：`Presentation.swift` 与 `NavigationDestination.swift` 改用 `RunLoopWait`，删掉 shim 里 `NSViewController` 的部分。补测试：用户关掉以 popover、模态窗口弹出的视图控制器时绑定写回；被别的页面盖住的发起者照样立刻 push。方法命名测试改用 `-[NSButton appKitNavigationIsOn]` 作扫描锚点。`RunLoopWait` 的检查时机同时调整，见决策日志。
2. **存取面板绑定**：改走 `sheet` / `modal` 的结果，删掉 shim 里 `NSSavePanel` 的部分和检查私有 setter 的测试。补测试：确认后写回、取消不动、重新绑定只写新绑定。方法命名测试不再有例外。
3. **NSControl 与 target 本身**：删掉重复声明与 `TargetActionProxy` 的变通；shim 已空，从四份 Package 清单里删掉这个 target，删掉目录。

没有询问就采用的假设：

- 存取面板的绑定只在经库的 `sheet` / `modal` 弹出时写回；App 自己调用 `begin` / `runModal` 时不写回，结果从完成回调里取。取消时绑定保持原值。依赖这个 fork 的 App（PrivateSymbols）与案例都只经 `sheet` / `modal` 使用，读完即清空。
- 弹出的就绪条件从「发起者的视图出现过」改为「发起者的视图此刻在可见窗口里」：视图出现过又离开窗口时（切到别的标签页、被导航栈里的新页面盖住），绑定再变成有值会等它回到屏幕上再弹，不再立刻弹出一个没有窗口可依附的 sheet。以模态窗口弹出不需要发起者的窗口，也照此等待。
- push 的就绪条件是「导航栈在屏幕上」而不是「发起者在屏幕上」：被盖住的发起者照旧立刻把新页面压到栈顶，与改动前一致。
- 盯着用户关闭的检查在整个弹出期间每轮 run loop 做一次，只是一次闭包调用，与 `navigationDestination` 的做法相同。
- AppKitNavigation 从此只能用 Xcode 27（macOS 27 SDK）编译。`Package@swift-6.0/6.1/6.2.swift` 来自上游，保留，只删 shim target；上游从来没有这个 target，删掉后与上游更接近。
- `UIKitNavigationShim` 也在交换方法，不在这一批的范围里。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-14 | Created as Draft | 用户不想再让库交换系统方法，并确认项目已统一使用 Xcode 27，要求删掉 AppKitNavigationShim |
| 2026-11-14 | 用户批准，开始实现 | 用户在对话里看过替代方案后批准开工，并选定存取面板的绑定保留 API、由库的 `sheet` / `modal` 写回；提案正文由 agent 起草，用户事前未审阅 |
| 2026-11-14 | push 的就绪条件看导航栈而不是发起者 | 起草时打算统一用「发起者在屏幕上」，实现前发现这会让被盖住的发起者推不出新页面，改变既有行为；弹出 sheet 和 popover 确实需要发起者的窗口，所以只在 push 上区别对待 |
| 2026-11-14 | 弹出之后立刻同步记一次「已列入 `presentedViewControllers`」，不只靠 run loop 检查 | 测试里用户在同一轮 run loop 内就关掉了 sheet，检查还没来得及看到它被弹出，于是永远等不到「离开列表」 |
| 2026-11-14 | `RunLoopWait` 除了 run loop 要休眠时，每次一轮运行结束时也检查，并排在所有同阶段的观察者（含 Core Animation 的提交）之后 | AppKit 每取一个事件都单独跑一轮 run loop，这样用户关闭弹出内容后，下一个事件被处理之前就已写回绑定，用户紧接着再要求弹出不会被这次写回冲掉。这个改动作用于所有用 `RunLoopWait` 的风格，AppKit 测试全部通过 |
| 2026-11-14 | 用户关闭后的写回不再与 AppKit 的关闭同步发生，`testPresentedSheetCanBePresentedAgainAfterTheUserDismissedIt` 改为等写回之后再立刻设回 `true` | 交换方法时写回发生在 `viewDidDisappear` 里，不交换就没有同步的时机。原测试在同一段同步代码里关闭 sheet 又设回 `true`，真实使用中两次操作之间总隔着事件循环；改后仍覆盖它要测的情形：中间那次 `false` 没被 `observe` 看到时，内容照样能再弹出 |
