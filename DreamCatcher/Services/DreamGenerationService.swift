import Foundation

struct DreamGenerationService {
    
    // MARK: - API Configuration
    
    private var openAIKey: String { Secrets.openAIKey }
    private var baseURL: String { Secrets.baseURL }
    
    // MARK: - Properties
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0 // 增加到60秒，避免生成慢导致超时
        config.timeoutIntervalForResource = 120.0
        return URLSession(configuration: config)
    }()
    
    // MARK: - Models
    
    private struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    private struct ChatCompletionResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
            
            struct Message: Codable {
                let content: String
            }
        }
    }
    
    // MARK: - Methods
    
    /// 优化用户的梦境描述 Prompt
    func optimizePrompt(input: String) async throws -> String {
        let systemPrompt = """
        You are an expert AI art prompt engineer.
        Your task is to convert the user's dream description into a high-quality, detailed English prompt for image generation.
        Style: Surrealistic, ethereal, dreamlike, 8k resolution, highly detailed.
        Output ONLY the English prompt, no other text.
        """
        
        return try await callOpenAI(systemPrompt: systemPrompt, userMessage: input)
    }
    
    /// 解析梦境并生成故事
    func analyzeDream(input: String) async throws -> (interpretation: String, story: String, psychologicalMapping: String, actionSuggestion: String) {
        let systemPrompt = """
        You are a professional dream interpreter and storyteller.
        Analyze the user's dream and provide four parts in JSON format.
        
        IMPORTANT: The output content MUST be in Simplified Chinese (简体中文).
        
        Required JSON structure:
        1. "interpretation": A deep psychological interpretation of the dream. (In Chinese)
        2. "story": A short, creative retelling of the dream as a mystical story. (In Chinese)
        3. "psychological_mapping": A concise mapping of dream symbols to user's subconscious state (e.g., "Flying -> Desire for freedom"). (In Chinese)
        4. "action_suggestion": A poetic and actionable suggestion for the user today based on the dream. (In Chinese)
        
        IMPORTANT: Return ONLY raw JSON. Do not wrap it in markdown code blocks like ```json ... ```.
        
        Format example:
        {
          "interpretation": "...",
          "story": "...",
          "psychological_mapping": "...",
          "action_suggestion": "..."
        }
        """
        
        let jsonString = try await callOpenAI(systemPrompt: systemPrompt, userMessage: input)
        
        // 清理 JSON 字符串 (移除可能的 Markdown 标记)
        let cleanedJsonString = cleanJsonString(jsonString)
        
        // 尝试解析 JSON
        guard let data = cleanedJsonString.data(using: .utf8),
              let result = try? JSONDecoder().decode(DreamAnalysisResult.self, from: data) else {
            print("Failed to parse JSON: \(jsonString)")
            // Fallback: 如果解析失败，尽量提取有用信息，避免直接显示 JSON
            return (
                interpretation: "梦境迷雾太浓，解析未能完全穿透...",
                story: input, // 如果生成失败，使用原话
                psychologicalMapping: "",
                actionSuggestion: "今晚，试着在枕边放一本笔记，再次捕捉梦的尾巴。"
            )
        }
        
        return (interpretation: result.interpretation, story: result.story, psychologicalMapping: result.psychologicalMapping, actionSuggestion: result.actionSuggestion)
    }
    
    // 预设的梦幻图片 URL 列表 (高分辨率 Unsplash 图片)
    private let fallbackImages = [
        "https://images.unsplash.com/photo-1518066000714-58c45f1a2c0a?q=80&w=2070&auto=format&fit=crop", // 星空
        "https://images.unsplash.com/photo-1502481851512-e9e2529bfbf9?q=80&w=2069&auto=format&fit=crop", // 迷雾森林
        "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=2072&auto=format&fit=crop", // 宇宙
        "https://images.unsplash.com/photo-1517544845501-bb78ccdad31e?q=80&w=2069&auto=format&fit=crop", // 极光
        "https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?q=80&w=1974&auto=format&fit=crop"  // 雨夜
    ]
    
    /// 生成图片，返回本地文件路径（相对路径或完整路径）
    func generateImage(prompt: String) async throws -> URL {
        // 尝试使用 flux 模型（高质量）
        do {
            return try await generateImageWithConfig(prompt: prompt, model: "flux", maxLength: 250)
        } catch {
            print("Flux model failed: \(error). Retrying with Turbo model...")
            // 失败重试：使用 turbo 模型（速度快）和更短的 Prompt
            do {
                return try await generateImageWithConfig(prompt: prompt, model: "turbo", maxLength: 150)
            } catch {
                print("Turbo model failed: \(error). Using fallback image.")
                // 最终降级：如果都失败，随机返回一张预设的梦幻图片
                if let fallbackString = fallbackImages.randomElement(),
                   let fallbackUrl = URL(string: fallbackString),
                   let (data, _) = try? await session.data(from: fallbackUrl) {
                     return try saveImageToDocuments(data: data)
                }
                throw error
            }
        }
    }
    
    private func generateImageWithConfig(prompt: String, model: String, maxLength: Int) async throws -> URL {
        // 1. 构建 Pollinations.ai URL
        // 优化策略：先截断原始字符串，再进行 URL 编码
        let truncatedRawPrompt = String(prompt.prefix(maxLength))
        
        // 使用自定义字符集，移除 '/' 和 '?'，确保它们被转义，防止破坏 URL 路径结构
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?")
        
        guard let encodedPrompt = truncatedRawPrompt.addingPercentEncoding(withAllowedCharacters: allowed) else {
             throw URLError(.badURL)
        }
        
        let seed = Int.random(in: 0...10000)
        // 添加 model 参数
        let urlString = "https://image.pollinations.ai/prompt/\(encodedPrompt)?width=1080&height=720&seed=\(seed)&nologo=true&model=\(model)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        print("Generated Image URL (\(model)): \(urlString)")
        
        do {
            // 2. 尝试下载 AI 生成的图片
            let (data, _) = try await session.data(from: url)
            return try saveImageToDocuments(data: data)
        } catch {
            throw error 
        }
    }
    
    // 保存到 Documents 目录，确保持久化存储
    private func saveImageToDocuments(data: Data) throws -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "dream_\(UUID().uuidString).jpg"
        let fileURL = documentsDir.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        // 建议返回相对文件名，但为了兼容性先返回完整 URL，View 层做解析
        return fileURL
    }
    
    private func cleanJsonString(_ input: String) -> String {
        var output = input
        // 移除 Markdown 代码块标记
        if output.hasPrefix("```json") {
            output = String(output.dropFirst(7))
        } else if output.hasPrefix("```") {
            output = String(output.dropFirst(3))
        }
        
        if output.hasSuffix("```") {
            output = String(output.dropLast(3))
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private struct DreamAnalysisResult: Codable {
        let interpretation: String
        let story: String
        let psychologicalMapping: String
        let actionSuggestion: String
        
        enum CodingKeys: String, CodingKey {
            case interpretation
            case story
            case psychologicalMapping = "psychological_mapping"
            case actionSuggestion = "action_suggestion"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            interpretation = try container.decode(String.self, forKey: .interpretation)
            story = try container.decode(String.self, forKey: .story)
            actionSuggestion = try container.decode(String.self, forKey: .actionSuggestion)
            
            // Try to decode psychologicalMapping as String first
            if let stringValue = try? container.decode(String.self, forKey: .psychologicalMapping) {
                psychologicalMapping = stringValue
            } else if let dictValue = try? container.decode([String: String].self, forKey: .psychologicalMapping) {
                // If it's a dictionary, convert to formatted string
                psychologicalMapping = dictValue.map { "- \($0.key): \($0.value)" }.joined(separator: "\n")
            } else {
                psychologicalMapping = "" // Fallback
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func callOpenAI(systemPrompt: String, userMessage: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ChatCompletionRequest(
            model: "gpt-3.5-turbo",
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userMessage)
            ],
            temperature: 0.7
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("OpenAI API Error: \(errorText)")
            }
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return result.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
