# 审查裁决清单

记录审查中判为误报、不值得修或暂缓处理的发现，以及没能在运行时验证的部分。每次审查之前先对照这份清单：已裁决、且理由仍然成立的条目直接跳过；新证据推翻了当初理由的，更新条目并重新裁决。

已修复的问题不在这里，它们的原因与验证写在各自的 commit message 和回归测试里。

## 误报或未复现

### `modalSession` 由 binding 关闭时结束了两次模态会话

- **裁决**：未复现出后果，不按 bug 处理。（2026-11-03）
- **理由**：binding 置空时，旧代码先调用 `endModalSession`、再关窗，关窗通知里又调用一次。可在 macOS 27.2 上测试，模态会话正常结束，`NSApp.modalWindow` 也归零，看不到任何异常。
- **现状**：修复「用户关窗不回写」时，结束会话的位置已经统一到窗口关闭通知这一处，顺带消除了重复调用。

### 焦点绑定直接调用 `becomeFirstResponder()`

- **裁决**：未复现症状，不按 bug 处理。（2026-11-03）
- **理由**：Apple 文档写明不要直接调用它，应改用 `NSWindow.makeFirstResponder(_:)`。但实测通过 binding 设置焦点一直能正常生效，`NSTextField` 自己的实现会把字段编辑器设为第一响应者。
- **现状**：已按文档改用 `makeFirstResponder(_:)`，行为不变。

### alert 作为 sheet 时没走 `beginSheetModal(for:)`，会不排版、按钮关不掉

- **裁决**：误报。（2026-11-06）
- **理由**：`NSWindow.sheet` 把 alert 的窗口直接交给 `NSWindow.beginSheet(_:)`，确实没调用 `NSAlert.beginSheetModal(for:)`。但在 macOS 27.2 上测试，alert 的标题和说明文字照常排版显示，点按钮也照常结束 sheet、把 binding 写回 `false`。同一处代码对存取面板是真问题：点「取消」关不掉 sheet，见提案 [0005-appkit-presentation-redesign](../Evolutions/0005-appkit-presentation-redesign.md) 第 8 条。
- **现状**：那份提案让 alert 改走自己的 `beginSheetModal(for:)`，`SheetPresentationTests` 里两条 alert 测试守着上面两点。

### `NSFontManager(font:)` 会建出一个和字体面板无关的新实例

- **裁决**：误报。（2026-11-03）
- **理由**：在 macOS 27.2 上实测，`NSFontManager()` 返回的就是 `NSFontManager.shared`。
- **复查条件**：将来某个系统版本上它不再返回共享实例时。

### 同一个视图控制器实例再次弹出时，覆盖上一次弹出的结束记录

- **裁决**：误报。（2026-11-14）
- **理由**：结束记录挂在被弹出的视图控制器上，只有一个槽位。可同一个 `BindingPresenter` 在上一次内容结束之前不会再弹出（`.ending` 阶段什么都不做），两个绑定同时弹出同一个实例又是 AppKit 本身不支持的，构造不出覆盖的场景。`main` 上交换方法时的 `_AppKitNavigation_onDismiss` 同样只有一个槽位。

### 自定义 presentation animator 不把视图移出窗口时，内容永远不算结束

- **裁决**：与改动前相同，不按问题处理。（2026-11-14）
- **理由**：判断结束要等被弹出的视图控制器的窗口不再可见。只有动画器在关闭时既不移除视图、也不关窗口才会卡住，而这样的动画器本身就把被关闭的视图留在了界面上。`main` 上交换方法时，报告关闭之后也是等同一个条件，提案 [0005-appkit-presentation-redesign](../Evolutions/0005-appkit-presentation-redesign.md) 有意这样定，好让有动画时 `onDismiss` 也在内容下屏之后才运行。
- **复查条件**：出现合理的动画器需要把视图留在窗口里时。

## 暂缓处理

### 上游 `UIKitNavigation` 的 `UITextField` 选区绑定同样把 UTF-16 偏移当成字符数

- **裁决**：确认是同类问题，fork 内不修，暂不向上游报告。（2026-11-03，暂不报告由用户决定）
- **理由**：AppKit 那份已按 UTF-16 换算修好。UIKit 那份是上游拥有的代码，fork 保持与上游一致，在 fork 里改会让以后的合并持续冲突。
- **复查条件**：上游自己修了，或者 fork 的 UIKit 用户撞上这个问题时。

### 视图控制器弹出与 push 的结束检测，和 `navigationDestination` 的记录写了两套

- **裁决**：不是缺陷，暂缓合并。（2026-11-14）
- **理由**：去掉 AppKitNavigationShim 时，弹出改用「先出现在列表里、再离开列表且下屏」的检测，形状和 push 的 `PushRecord` 相近，但判断条件不同（`presentedViewControllers` 对父视图控制器）。push 那套来自另一份提案，合成一个共用 helper 属于单独的重构。
- **复查条件**：其中一套要改检测条件时，一并合并。

## 有意的取舍

这些发现确实存在，是方案主动接受的代价，理由仍成立就不再重审。

### 去掉 NSControl 的重复声明后，旧 SDK 编不过 AppKitNavigation

- **裁决**：按用户决定，不修。（2026-11-14）
- **理由**：macOS 27 以前的 SDK 没有公开 `addTarget(_:action:for:)`，`Package@swift-6.0/6.1/6.2.swift` 选中的 Xcode 26 及更早版本编到 `TargetActionProxy` 时报错。shim 里的这段声明当初就写明「macOS 27 SDK 成为最低要求时整段删掉」；用户确认项目已统一使用 Xcode 27。fork 的 CI 仍用 Xcode 16.4，在 `main` 上本来就是红的（examples 任务失败）。其余几个库在旧 Xcode 上不受影响。
- **复查条件**：需要重新支持 Xcode 26 时。

### `destination` 的 present 闭包从别的视图控制器弹出时，察觉不到用户关闭

- **裁决**：不修。（2026-11-14）
- **理由**：察觉用户关闭只看调用 `destination` 的那个视图控制器的 `presentedViewControllers`，文档已写明。改动前交换 `dismissViewController:` 不分发起者，所以这是这次引入的差别。但从别的视图控制器弹 sheet 没有实际用处（sheet 挂在同一个窗口上），要支持就得读被弹出者的 `presentingViewController`，它不是弱引用，发起者释放时读取会崩。
- **复查条件**：有调用方确实需要从别处弹出时。

### 存取面板的 URL 绑定只在经库的 `sheet` / `modal` 弹出时写回

- **裁决**：按用户决定，不修。（2026-11-14）
- **理由**：不交换私有方法，就只有面板的结果（`beginSheetModal` 的回调、`runModal` 的返回值）能告诉库用户选了什么，而只有运行面板的一方看得到。App 自己 `begin` / `runModal` 时从结果里取即可。依赖这个 fork 的 App 与案例都经 `sheet` / `modal` 使用。
- **复查条件**：有 App 需要自己运行面板又想用绑定时。

### 弹出期间每轮 run loop 都检查一次

- **裁决**：不修。（2026-11-14）
- **理由**：察觉用户关闭弹出的视图控制器，靠的是弹出期间每轮 run loop（休眠前和每次运行结束）调用一次检查闭包，取一次 `presentedViewControllers`。改动前视图控制器的弹出没有这项开销，sheet、popover、push 的等待早就这样做。一次闭包调用加一个小数组，与处理事件本身相比可以忽略，这是不交换方法的代价。
- **复查条件**：出现可测的性能问题时（用 `sample` 采样）。

### 栈不在任何窗口里时，push 推迟到它出现

- **裁决**：剩下的这部分不修。（2026-11-14）
- **理由**：改动前只要发起者出现过一次就立刻 push；现在要等栈所在的窗口在屏幕上或已最小化。最小化的情形已修好，有回归测试。还剩未选中的标签页：栈的视图不在任何窗口里，push 推迟到标签页被选中时补上，不会丢。不交换 `viewDidAppear` 就无从知道视图是否出现过。
- **复查条件**：有 App 依赖往隐藏标签页里的栈 push 时。

## 系统限制

### Xcode 26.6 上 `observe(_:)` 的两条 `@isolated(any)` 转换警告

- **裁决**：旧编译器的限制，不修。（2026-11-04）
- **理由**：`observe(_:)` 必须同步执行传入的 `@isolated(any)` 闭包，编译器为此报「converting @isolated(any) function … to synchronous function type」。Swift 6.4 上用 `@diagnose(ConversionFromIsolatedAnyToSynchronous, as: ignored)` 屏蔽了；Swift 6.2（Xcode 26.6）不认识这个属性，只能去掉签名里的 `@isolated(any)`，而那会让 `observe { @MainActor in … }` 这类显式指定隔离的写法退化。
- **复查条件**：不再支持 Xcode 26.6 时，这一条直接删掉。

### 字体绑定只在响应链上有对象实现 `changeFont(_:)` 时生效

- **裁决**：AppKit 自身的行为，库里无法绕开。（2026-11-03）
- **理由**：实测发现，响应链上没有实现 `changeFont(_:)` 的对象时，`NSFontManager.sendAction()` 返回 `false`，`addFontTrait(_:)` 也什么都不做，字体面板的改动根本不会发出来。
- **现状**：已写进 `NSFontManager.bind(font:)` 的文档注释。

## 未在运行时验证

### transient popover 被点外部关闭时的回写

- `present(style: .popover(...))` 在用户关闭时把 binding 写回 `nil`。2026-11-14 起不再依靠 AppKit 调用 `dismissViewController:`：只要 popover 关闭后 AppKit 把视图控制器移出发起者的 `presentedViewControllers`、它的窗口也不再可见，就会写回。`ViewControllerPresentationTests` 用 `NSPopover.close()` 关闭的情形有测试覆盖；点击 popover 外部触发的关闭在单元测试里没法模拟，那条路径是否也走 `close()`，还没有验证。
