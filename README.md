# DreamCatcher - 在星光中捕捉你的梦境

DreamCatcher 是一款基于 iOS 平台的智能梦境记录与分析应用。它结合了语音识别、AI 文本分析和 AI 绘画技术，将用户零散的梦境碎片转化为可视化的故事、心理分析和艺术画作，帮助用户探索潜意识的世界。

## ✨ 核心功能

*   **🎙️ 语音捕获**：一键录制梦境叙述，实时转录为文字，不错过任何转瞬即逝的灵感。
*   **🧠 AI 深度解析**：
    *   **梦境重构**：将碎片化的描述整理为通顺的微小说。
    *   **心理映射**：分析梦中意象（如飞行、深海）对应的潜意识心理状态。
    *   **潜意识回响**：提供深度的心理学解读。
    *   **今日行动**：基于梦境分析，给出充满诗意的每日行动建议。
*   **🎨 AI 梦境绘图**：自动根据梦境内容生成高质量的艺术画作（支持 8K 分辨率、超现实风格）。
*   **📅 梦境日历**：以月视图回顾历史梦境，记录心路历程。
*   **📮 梦境明信片**：生成精美的梦境明信片，支持高清分享到社交媒体。
*   **🏷️ 智能标签**：支持手动或自动管理梦境标签（如美梦、噩梦、预知梦等）。

## 🛠️ 技术栈

*   **平台**：iOS 17.0+
*   **开发语言**：Swift 5.9
*   **UI 框架**：SwiftUI
*   **数据存储**：SwiftData (Core Data 继任者)
*   **语音识别**：Speech Framework (SFSpeechRecognizer)
*   **AI 服务**：
    *   **文本分析**：OpenAI GPT-3.5 Turbo / GPT-4
    *   **图像生成**：Pollinations.ai (Flux/Turbo 模型)
*   **架构模式**：MVVM (Model-View-ViewModel)

## 📂 项目结构

```
DreamCatcher/
├── App/
│   ├── DreamCatcherApp.swift    // 应用入口，配置 SwiftData
│   └── ContentView.swift        // 根视图
├── Models/
│   └── DreamItem.swift          // 梦境数据模型 (SwiftData)
├── ViewModels/
│   └── HomeViewModel.swift      // 核心业务逻辑：录音、API调用、状态管理
├── Views/
│   ├── HomeView.swift           // 主页：录音交互与状态展示
│   ├── DreamResultView.swift    // 结果页：展示分析结果与图片
│   ├── CalendarView.swift       // 历史记录：日历视图
│   └── Components/              // 通用组件
│       ├── AudioVisualizerView  // 音频波形可视化
│       ├── ParticleBackground   // SceneKit 粒子背景
│       └── ...
├── Services/
│   ├── SpeechManager.swift      // 语音录制与转录服务
│   └── DreamGenerationService.swift // AI 接口封装 (OpenAI + Pollinations)
└── Utils/
    ├── Secrets.swift            // API Keys 配置
    └── ImageUtils.swift         // 图片处理工具
```

## 🚀 快速开始

1.  **环境要求**：
    *   Xcode 15.0 或更高版本
    *   iOS 17.0 模拟器或真机

2.  **获取代码**：
    ```bash
    git clone [repository_url]
    cd DreamCatcher
    ```

3.  **配置密钥**：
    打开 `DreamCatcher/Utils/Secrets.swift`，填入你的 API Key：
    ```swift
    enum Secrets {
        static let openAIKey = "sk-xxxxxxxxxxxx" // 你的 OpenAI Key
        static let baseURL = "https://api.openai.com/v1" // 或自定义代理地址
    }
    ```

4.  **运行**：
    使用 Xcode 打开 `DreamCatcher.xcodeproj`，选择目标设备，点击 Run (Cmd+R)。

## ⚠️ 注意事项

*   **真机调试**：语音识别功能建议在真机上测试，模拟器可能无法接收麦克风输入。
*   **网络权限**：App 需要访问互联网以调用 AI 接口，请确保网络通畅。
*   **隐私权限**：首次启动时需授权麦克风和语音识别权限。

## 📝 待优化项 (Roadmap)

*   [ ] **图片路径修复**：将数据库中的图片路径由绝对路径改为相对路径，防止沙盒变化导致图片丢失。
*   [ ] **性能优化**：优化日历页面的数据加载逻辑，引入分页查询。
*   [ ] **多语言支持**：引入 `.strings` 文件，支持英文界面。
*   [ ] **云同步**：集成 iCloud Sync，实现多设备数据同步。

## 📄 许可证

本项目仅供学习与交流使用。
