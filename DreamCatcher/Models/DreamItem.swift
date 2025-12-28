import Foundation
import SwiftData

@Model
class DreamItem {
    var id: UUID
    var date: Date
    var originalText: String // 语音转录原文
    var optimizedPrompt: String // AI 优化后的 Prompt
    var imageUrl: String // 本地文件路径 (相对于 Documents 目录)
    var interpretation: String // 梦境解析
    var story: String // 梦境故事
    var psychologicalMapping: String = "" // 心理映射
    var actionSuggestion: String = "" // 今日行动建议
    var textContent: String = "" // 纯文本输入内容
    var tags: [String] = [] // 情绪标签
    
    init(id: UUID = UUID(), date: Date = Date(), originalText: String, optimizedPrompt: String = "", imageUrl: String = "", interpretation: String = "", story: String = "", psychologicalMapping: String = "", actionSuggestion: String = "", textContent: String = "", tags: [String] = []) {
        self.id = id
        self.date = date
        self.originalText = originalText
        self.optimizedPrompt = optimizedPrompt
        self.imageUrl = imageUrl
        self.interpretation = interpretation
        self.story = story
        self.psychologicalMapping = psychologicalMapping
        self.actionSuggestion = actionSuggestion
        self.textContent = textContent
        self.tags = tags
    }
}
