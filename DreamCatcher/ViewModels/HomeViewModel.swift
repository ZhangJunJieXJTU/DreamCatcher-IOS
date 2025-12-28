import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class HomeViewModel: ObservableObject {
    @Published var speechManager = SpeechManager()
    @Published var dreamService = DreamGenerationService()
    
    @Published var isProcessing: Bool = false
    @Published var currentDreamItem: DreamItem?
    
    // 用于动画的状态
    @Published var isRecordingPressed: Bool = false
    
    // 用于处理流程的步骤状态
    @Published var processingStep: ProcessingStep = .idle
    
    // 录音计时
    @Published var recordingDuration: TimeInterval = 0
    private var timer: AnyCancellable?
    
    // 备注文本
    @Published var dreamNote: String = ""
    @Published var showNoteInput: Bool = false
    
    // 输入模式
    enum InputMode {
        case audio
        case text
    }
    @Published var inputMode: InputMode = .audio
    
    // 文字输入
    @Published var textInput: String = "" {
        didSet {
            // 自动保存草稿
            UserDefaults.standard.set(textInput, forKey: "dream_text_draft")
        }
    }
    
    // 错误信息
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    init() {
        // 加载草稿
        self.textInput = UserDefaults.standard.string(forKey: "dream_text_draft") ?? ""
    }
    
    enum ProcessingStep {
        case idle
        case transcribing
        case optimizing
        case generating
        case completed
    }
    
    func startRecording() {
        do {
            try speechManager.startRecording()
            withAnimation {
                isRecordingPressed = true
                recordingDuration = 0
            }
            
            // 启动计时器
            timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                .sink { [weak self] _ in
                    self?.recordingDuration += 1
                }
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        speechManager.stopRecording()
        timer?.cancel()
        timer = nil
        
        withAnimation {
            isRecordingPressed = false
        }
        
        // 如果录音内容不为空，则弹出备注输入框
        if !speechManager.transcript.isEmpty {
             withAnimation {
                 showNoteInput = true
             }
        }
    }
    
    func confirmDream() {
        showNoteInput = false
        // 开始处理流程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
             self.isProcessing = true
             Task {
                 await self.processDream()
             }
         }
    }
    
    func processDream() async {
        let transcript = inputMode == .audio ? speechManager.transcript : textInput
        
        withAnimation { processingStep = .optimizing }
        
        do {
            // 并行优化：尽早启动耗时的梦境解析任务
            // 1. 启动并行任务：解析梦境 (耗时较长) & 优化 Prompt (耗时较短)
            async let analysisTask = dreamService.analyzeDream(input: transcript)
            async let promptTask = dreamService.optimizePrompt(input: transcript)
            
            // 2. 等待 Prompt 完成 (Step 1)
            let prompt = try await promptTask
            
            withAnimation { processingStep = .generating }
            
            // 3. Prompt 完成后，立即启动生图任务
            async let imageTask = dreamService.generateImage(prompt: prompt)
            
            // 4. 等待生图和解析全部完成
            let (url, result) = try await (imageTask, analysisTask)
            
            // 5. 创建数据模型
            // 使用用户输入的备注作为 originalText，如果为空则使用转录文本
            let textToSave = dreamNote.isEmpty ? transcript : dreamNote
            let newItem = DreamItem(
                originalText: textToSave,
                optimizedPrompt: prompt,
                imageUrl: url.absoluteString, // 实际应用中应下载图片并保存到本地
                interpretation: result.interpretation,
                story: result.story,
                psychologicalMapping: result.psychologicalMapping,
                actionSuggestion: result.actionSuggestion,
                textContent: inputMode == .text ? textInput : ""
            )
            
            withAnimation {
                self.currentDreamItem = newItem
                self.processingStep = .completed
            }
            
        } catch {
            print("Error processing dream: \(error)")
            // 处理错误状态
            self.errorMessage = "网络连接似乎有点问题，请检查网络后重试。\n(\(error.localizedDescription))"
            self.showErrorAlert = true
            self.processingStep = .idle
        }
    }
    
    func saveDream(context: ModelContext) {
        if let item = currentDreamItem {
            context.insert(item)
            isProcessing = false
            currentDreamItem = nil
            processingStep = .idle
            speechManager.transcript = "" // 重置录音
            dreamNote = "" // 重置备注
            if inputMode == .text {
                textInput = "" // 重置文字输入
            }
        }
    }
    
    // 放弃保存，清理状态
    func discardDream() {
        isProcessing = false
        currentDreamItem = nil
        processingStep = .idle
        speechManager.transcript = "" // 重置录音
        dreamNote = "" // 重置备注
        if inputMode == .text {
            textInput = "" // 重置文字输入
        }
    }
    
    // 清空文本内容
    func clearText() {
        textInput = ""
    }
}
