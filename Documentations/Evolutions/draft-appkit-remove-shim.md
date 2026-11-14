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
2. **存取面板绑定**（已完成）：改走 `sheet` / `modal` 的结果，删掉 shim 里 `NSSavePanel` 的部分和检查私有 setter 的测试。补测试：确认后写回、取消不动、重新绑定只写新绑定。方法命名测试不再有例外。案例里的存储面板改为弹出前先清空上次选的 URL。
3. **NSControl 与 target 本身**（已完成）：删掉重复声明与 `TargetActionProxy` 的变通；shim 已空，从四份 Package 清单里删掉这个 target，删掉目录。

没有询问就采用的假设：

- 存取面板的绑定只在经库的 `sheet` / `modal` 弹出时写回；App 自己调用 `begin` / `runModal` 时不写回，结果从完成回调里取。取消时绑定保持原值——交换方法的旧实现会写成 `nil`，用户确认改用新语义。依赖这个 fork 的 App（PrivateSymbols）与案例都只经 `sheet` / `modal` 使用，读完即清空。
- 弹出的就绪条件从「发起者的视图出现过」改为看它此刻所在的窗口：sheet 与 popover 要求窗口在屏幕上，视图出现过又离开窗口时（切到别的标签页、被导航栈里的新页面盖住），绑定再变成有值会等它回到屏幕上再弹，不再立刻弹出一个没有窗口可依附的 sheet；模态窗口与自定义转场不需要发起者的窗口，窗口最小化时也照常弹出。
- push 的就绪条件看导航栈所在的窗口而不是发起者：被盖住的发起者照旧立刻把新页面压到栈顶，窗口最小化时也照常 push，与改动前一致；栈的视图不在任何窗口里时（未选中的标签页）推迟到它出现。
- 盯着用户关闭的检查在整个弹出期间每轮 run loop 做一次，只是一次闭包调用，与 `navigationDestination` 的做法相同。
- AppKitNavigation 从此只能用 Xcode 27（macOS 27 SDK）编译。`Package@swift-6.0/6.1/6.2.swift` 来自上游，保留，只删 shim target；上游从来没有这个 target，删掉后与上游更接近。
- `UIKitNavigationShim` 也在交换方法，不在这一批的范围里。

后续项：

- 把弹出与 push 两套「先出现、再离开且下屏」的结束检测合成一个共用 helper（见 `Internal/ReviewDecisions.md`）。
- fork 的 CI 仍用 Xcode 16.4，编不过 AppKitNavigation 了；要么换成 Xcode 27，要么不再编它。CI 在这次改动之前就已经是红的。
- 窗口 sheet（`NSWindow.sheet`）与模态会话（`modalSession`）由绑定关闭时，同样等到这一轮 run loop 结束才写回，`main` 上就是这样。可以照视图控制器的做法，在关闭调用返回后立刻检查一次。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-14 | Created as Draft | 用户不想再让库交换系统方法，并确认项目已统一使用 Xcode 27，要求删掉 AppKitNavigationShim |
| 2026-11-14 | 用户批准，开始实现 | 用户在对话里看过替代方案后批准开工，并选定存取面板的绑定保留 API、由库的 `sheet` / `modal` 写回；提案正文由 agent 起草，用户事前未审阅 |
| 2026-11-14 | push 的就绪条件看导航栈而不是发起者 | 起草时打算统一用「发起者在屏幕上」，实现前发现这会让被盖住的发起者推不出新页面，改变既有行为；弹出 sheet 和 popover 确实需要发起者的窗口，所以只在 push 上区别对待 |
| 2026-11-14 | 弹出之后立刻同步记一次「已列入 `presentedViewControllers`」，不只靠 run loop 检查 | 测试里用户在同一轮 run loop 内就关掉了 sheet，检查还没来得及看到它被弹出，于是永远等不到「离开列表」 |
| 2026-11-14 | `RunLoopWait` 除了 run loop 要休眠时，每次一轮运行结束时也检查，并排在所有同阶段的观察者（含 Core Animation 的提交）之后 | AppKit 每取一个事件都单独跑一轮 run loop，这样用户关闭弹出内容后，下一个事件被处理之前就已写回绑定，用户紧接着再要求弹出不会被这次写回冲掉。这个改动作用于所有用 `RunLoopWait` 的风格，AppKit 测试全部通过 |
| 2026-11-14 | 用户关闭后的写回不再与 AppKit 的关闭同步发生，`testPresentedSheetCanBePresentedAgainAfterTheUserDismissedIt` 改为等写回之后再立刻设回 `true` | 交换方法时写回发生在 `viewDidDisappear` 里，不交换就没有同步的时机。原测试在同一段同步代码里关闭 sheet 又设回 `true`，真实使用中两次操作之间总隔着事件循环；改后仍覆盖它要测的情形：中间那次 `false` 没被 `observe` 看到时，内容照样能再弹出 |
| 2026-11-14 | 存取面板测试经私有方法 `completeWithReturnCode:url:urls:` 模拟用户确认，私有方法只出现在测试里 | 面板在另一个进程里运行，本进程里的 `ok(_:)` 直接抛「not implemented」，公开 API 里没有别的办法让面板以「确定」结束；调用前先检查方法还在，不在就让测试失败而不是崩溃。旧测试同样调用私有 setter。临时关掉写回时，四个确认用例都会失败 |
| 2026-11-14 | 案例里的存储面板在弹出前先清空 `savedURL` | 取消不再动绑定，不清空的话，取消后的记录会显示上一次选的文件名 |
| 2026-11-14 | 自审：模态窗口、自定义转场与 push 在窗口最小化时也就绪 | 自审指出它们本不需要发起者的窗口在屏幕上，改动后却会一直等到窗口还原，而改动前是立刻弹出。先写了两条在最小化窗口上弹出与 push 的测试，修前失败、修后通过 |
| 2026-11-14 | 自审其余发现登记进 `Internal/ReviewDecisions.md` | 共 10 条：1 条已修（上一行）；2 条误报；1 条暂缓；5 条是方案有意接受的代价；存储面板取消时的写法留给用户定，见下一行 |
| 2026-11-14 | 存储面板取消时不动绑定，待用户确认 | 在 `main` 上实测，交换方法的旧实现在用户取消时会把绑定写成 `nil`。用户开工前选的方案写的是「取消时绑定不变」，当时没有说明旧行为，所以交付时请用户再确认一次 |
| 2026-11-14 | 实现完成，待用户看过后收尾 | 文档已同步：本提案、`present` / `destination` / `navigationDestination` 与存取面板绑定的文档注释、`Internal/ReviewDecisions.md`。改动只涉及内部机制与既有 API 的语义，不需要另写使用指南或实现说明，也没有新术语 |
| 2026-11-14 | 由绑定触发的视图控制器关闭，在 `dismiss(_:)` 返回后立刻检查、当场写回 | 用户指出 AppKit 的 `dismiss(_:)` 返回时内容已经离屏，与 UIKit 不同。交换方法时这条路是同步写回的，去掉之后却要等这一轮 run loop 结束；用户选择只恢复这一条，用户自己关掉的仍在这一轮结束时写回。新测试借自定义事务键在绑定变化应用完的那一刻检查 `onDismiss` 是否已运行，修前失败、修后通过 |
| 2026-11-14 | 用户确认：存储面板取消时绑定保持原值 | 用户看过旧实现「取消即写成 `nil`」的实测结果后，仍选择取消时不动绑定；案例在弹出前清空 `savedURL` 的那一行保留 |
