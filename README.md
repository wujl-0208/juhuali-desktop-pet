# 菊花梨 · macOS 桌面宠物

用 Swift 和 AppKit 写成的原生 macOS 桌宠。角色取自《洛克王国：世界》里的**菊花梨**，跑起来是一只浮在桌面上的小家伙：会自己溜达、盯着你的鼠标看、被你戳、被你拖，闲久了会打瞌睡。

运行时只用 macOS 系统框架（AppKit + ImageIO）。没有 WebView、没有浏览器内核、没有网络请求，也不依赖 Python / Node.js —— 角色图集、动画帧和配置全部打包进 `.app`，断网照常工作。

- **语言 / UI**：Swift 6 + AppKit，939 行源码，11 个源文件
- **系统要求**：macOS 13 及以上，Apple Silicon（arm64）
- **产物**：约 4 MB 的独立 `.app`（可执行文件约 211 KB，其余是美术资源）
- **依赖**：零第三方依赖

---

## 快速开始

```bash
# 构建 + 打包，默认输出到工程上级目录的 菊花梨.app
zsh build-app.sh

# 或者指定输出路径
zsh build-app.sh /Applications/菊花梨.app
```

构建完成后在 Finder 里双击 `菊花梨.app`。桌宠会出现在**主显示器可用区域的下方**（避开 Dock 和菜单栏）。

> **首次打开被系统拦下？**
> 本地自行编译的应用只做了临时签名（`codesign --sign -`），macOS 会提示"无法验证开发者"。在 Finder 中**右键 → 打开**，再确认一次即可；后续双击正常。没有做公证（notarization），也不打算做。
>
> 如果提示"无法载入菊花梨素材"，说明 `.app` 里的 `Contents/Resources/Animations/spritesheet.png` 缺失或不完整 —— 重新跑一次 `build-app.sh`。

---

## 怎么玩

右键角色直接出菜单，菜单栏另有一个常驻的 🌼 图标。

### 对着角色操作

| 操作 | 反应 |
| --- | --- |
| 鼠标靠近 | 进入观察状态，用 16 个方向的帧转头看你 |
| 继续靠近 | 主动向你走一小段（最多 3 秒），之后进入 22 秒冷却 |
| 单击 | 挥手打招呼 |
| 短时间内连点 | 依次升级：挥手 → 疑惑 → 左右闪躲（点第 4 下起会一边躲一边挪） |
| 双击 | 原地跳一下 |
| 右键 | 弹出功能菜单（休息 / 唤醒 / 暂停自动移动 / 始终置顶 / 设置 / 退出） |
| 按住拖动 | 暂停自动行为、跟着指针走；松手后自动修正到当前显示器可见区域内 |
| 长时间不理会 | 打瞌睡 → 睡着；鼠标靠近、点击或拖动都会唤醒 |

角色窗口是**透明无边框**的，并且按当前帧的 Alpha 通道做命中判定 —— 点角色周围那圈空白，鼠标事件会直接穿透到下面的窗口，不会误触。

### 菜单栏 🌼

提供 `设置…`、`让菊花梨休息`、`唤醒`、`退出桌宠`。

### 设置项

菜单栏或右键菜单里的「设置…」打开原生设置窗口，选项写入 `UserDefaults`，重启后保留。

| 设置 | 范围 / 默认 | 说明 |
| --- | --- | --- |
| 桌宠大小 | 70% – 180%（默认 100%） | 按基准尺寸 96×104 缩放 |
| 动画速度 | 0.5× – 1.6×（默认 1.0×） | 全局帧率倍率 |
| 自动移动 | 开 | 关闭后不再自己溜达 |
| 跟随鼠标方向 | 开 | 关闭后不会因鼠标移动而转头 |
| 鼠标靠近互动 | 开 | 关闭后接近也不会来追你 |
| 始终置顶 | 开 | 关闭后降为普通窗口层级 |
| 音效（预留） | 关 | 目前只有开关，尚未接入音频 |

---

## 行为参数

所有可调数值集中在 `Sources/Models/PetConfig.swift` 一个文件里，改完重新构建即可生效。

| 参数 | 值 | 含义 |
| --- | --- | --- |
| `senseDistance` | 290 pt | 感知鼠标的距离 |
| `approachDistance` | 135 pt | 触发"走近你"的距离 |
| `stopDistance` | 66 pt | 走到多近就停下 |
| `wakeDistance` | 150 pt | 睡眠中的唤醒距离 |
| `walkSpeed` / `runSpeed` | 26 / 49 pt/s | 自动溜达速度 |
| `approachSpeed` | 25 pt/s | 主动靠近的速度 |
| `approachDuration` | 3.0 s | 单次靠近的最长时间 |
| `approachCooldown` | 22 s | 靠近行为的冷却 |
| `jumpVelocity` / `gravity` | 235 / 720 | 跳跃初速度与重力 |
| `sleepAfter` | 150 s | 无互动多久开始犯困 |
| `randomInterval` | 12 – 24 s | 自动行为的随机间隔 |
| `doubleClickDelay` | 0.30 s | 单击判定窗口（等这么久确认不是双击） |

刷新频率按状态自适应：活跃 20 Hz，待机 / 观察 8 Hz，睡眠降到每 0.5 秒一次，尽量少占 CPU。睡眠时主计时器也一并降频。

---

## 项目结构

```text
juhuali-desktop-pet/
├── Package.swift                     SwiftPM 源码索引（供 IDE 阅读）
├── build-app.sh                      构建 + 打包独立 .app
├── Sources/
│   ├── App/
│   │   ├── main.swift                入口
│   │   └── AppDelegate.swift         启动、菜单栏、--preview-* 参数
│   ├── Models/PetConfig.swift        全部行为参数
│   ├── Pet/
│   │   ├── PetWindow.swift           透明无边框窗口
│   │   ├── PetStateMachine.swift     状态机（唯一决定状态切换的地方）
│   │   ├── PetAnimationManager.swift 图集解码、动画片段、Alpha 命中判定
│   │   ├── MouseInteractionManager.swift  鼠标采样与距离分区
│   │   ├── MovementController.swift  移动、跳跃物理、边界修正
│   │   └── PetController.swift       控制器：把上面这些拧在一起
│   └── Settings/
│       ├── PetSettings.swift         UserDefaults 持久化
│       └── SettingsWindowController.swift  原生设置窗口
├── Resources/
│   ├── Info.plist
│   ├── AppIcon.icns
│   └── Animations/spritesheet.png    1536×2288，8 列 × 11 行，单元格 192×208
├── Tests/main.swift                  状态机冒烟测试
└── Tools/MakeIcon.swift              从图集首帧生成 .icns 的辅助工具
```

`Package.swift` 只用于在 IDE 里阅读源码；**要生成完整的 `.app` 请用 `build-app.sh`**。

构建脚本做的事：用 `xcrun swiftc` 以 `-O -swift-version 5 -target arm64-apple-macos13.0` 编译全部 `Sources/**/*.swift`，链接 AppKit 与 ImageIO，拷贝 `Info.plist` 和美术资源，`plutil -lint` 校验后做临时签名。

---

## 图集与动画映射

`spritesheet.png` 是 8 列 × 11 行的网格，每格 192×208。启动时**一次性解码全部用到的帧并缓存**（含位图，供 Alpha 命中判定用），动画过程中不再解码。

| 行 | 帧数 | 用途 |
| --- | --- | --- |
| 0 | 7 | 待机呼吸（循环用 0–5 帧）；同时承载犯困 0→1→2、睡着停在第 2 帧、唤醒 2→1→0 |
| 1 | 8 | 向右移动（走 / 跑共用，靠帧率区分） |
| 2 | 8 | 向左移动 |
| 3 | 4 | 单击反应（挥手） |
| 4 | 5 | 跳跃悬空帧；双击跳跃复用它，拖动时取第 2、3 帧 |
| 5 | 8 | 当前未被引用 |
| 6 | 6 | 右键反应 |
| 7 | 6 | 当前未被引用 |
| 8 | 6 | 短时间连点时的疑惑反应 |
| 9 / 10 | 8 + 8 | 共 16 个观察方向帧，按鼠标方位角选取 |

> 原始图集里没有独立的 `walk`、`sleep`、`dragged` 行。本项目通过**同一套双足帧降速**实现走路（`walkFPS` 6.0，对 `runFPS` 9.0），休息复用第 0 行已有的闭眼帧，拖动复用跳跃行里的悬空帧。这些映射只发生在新 App 里，**不修改原图集**。

### 想加一个动作

1. 在 `spritesheet.png` 上增加透明动画帧，保持现有角色结构；如果行列数变了，同步改 `PetConfig` 里的 `atlasColumns` / `atlasRows`。
2. 在 `PetAnimationManager` 的预加载计数数组 `counts` 里加入该行的帧数。
3. 用 `AnimationClip(name, row, columns, fps, loops, nextState)` 定义播法，在 `PetController.stateChanged` 里挂到对应状态上。
4. 如果要引入新状态，先在 `PetStateMachine` 里加 `PetState` 和允许的事件转换 —— 状态能打断谁是它一个人说了算。
5. 跑 `zsh build-app.sh`，重点检查角色轮廓、透明点击区域和动作切换是否正常。

---

## 开发与验证

**状态机冒烟测试**（断言各状态的事件转换，不依赖 GUI）：

```bash
xcrun swiftc -O -o /tmp/petstate-test Sources/Pet/PetStateMachine.swift Tests/main.swift \
  && /tmp/petstate-test
# PetStateMachine smoke test passed
```

**预览指定画面**（仅供本地调试，正常双击不会触发）：

```bash
open -n 菊花梨.app --args --preview-sleep      # 直接进睡眠画面
open -n 菊花梨.app --args --preview-settings   # 直接开设置窗口
```

**当前验证环境**：macOS 26.6.2 / Apple Silicon (arm64) / Apple Swift 6.4，编译通过并做过图形启动检查。

---

## 已知限制

- **仅 arm64**：`build-app.sh` 的 target 写死了 `arm64-apple-macos13.0`，Intel Mac 需要自己改这一行。
- **无签名公证**：只做临时签名，首次打开要手动放行，也没法直接发给别人双击运行。
- **音效未实现**：设置里的开关是给后续动作音效预留的。
- **图集第 5、7 行未使用**：会随启动一起预解码，属于可扩展空间。

---

## 版权与许可

- **代码**（`Sources/`、`Tools/`、`build-app.sh`、`Tests/`）：MIT，见 [LICENSE](LICENSE)。
- **角色与美术素材**：菊花梨（Juhuali）是《洛克王国：世界》中的角色，相关形象与图像素材版权归原权利方所有。仓库内的 `spritesheet.png`、`AppIcon.icns` 仅用于**个人本地运行与学习**，**不适用 MIT 许可**，请勿用于商业用途或再分发。

仓库保持私有即出于此考虑。纯代码部分想复用的话，请自行替换一套你有权使用的素材。
