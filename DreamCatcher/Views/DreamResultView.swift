import SwiftUI

struct DreamResultView: View {
    let dreamItem: DreamItem
    var onSave: (() -> Void)? = nil // Optional save action
    var onShare: () -> Void
    var onDiscard: (() -> Void)? = nil // 新增：放弃回调
    
    var body: some View {
        ZStack {
            // 背景：柔和的米白色或纸质纹理
            Color(hex: "FDFBF7").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) { // 减小间距，更紧凑
                    // 1. 顶部图片卡片
                    DreamImageCard(imageUrl: dreamItem.imageUrl, date: dreamItem.date)
                        .padding(.top, 10)
                        .padding(.horizontal, 4) // 额外增加一点内缩，确保两侧留白
                    
                    // 1.5 标签管理 (Tag Management)
                    TagSelectionView(dreamItem: dreamItem)
                    
                    // 2. 梦境重构 (Dream Reconstruction)
                    ContentSection(
                        icon: "quote.opening",
                        title: "梦境重构",
                        content: dreamItem.story.isEmpty ? dreamItem.originalText : dreamItem.story,
                        fontDesign: .serif
                    )
                    
                    // 3. 心理映射 (Psychological Mapping)
                    if !dreamItem.psychologicalMapping.isEmpty {
                        ContentSection(
                            icon: "brain.head.profile",
                            title: "心理映射",
                            content: dreamItem.psychologicalMapping,
                            fontDesign: .monospaced
                        )
                    }
                    
                    // 4. 深度解读 (Interpretation)
                    ContentSection(
                        icon: "sparkles",
                        title: "潜意识的回响",
                        content: dreamItem.interpretation,
                        fontDesign: .default
                    )
                    
                    // 5. 今日行动建议 (Action Suggestion)
                    if !dreamItem.actionSuggestion.isEmpty {
                        ActionSuggestionCard(suggestion: dreamItem.actionSuggestion)
                    }
                    
                    // 底部留白，防止内容被按钮遮挡
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 20) // 调整为 20，适应小屏
            }
            .scrollIndicators(.hidden)
            
            // 底部固定按钮栏
            VStack {
                Spacer()
                
                HStack(spacing: 16) {
                    // 放弃按钮 (仅在预览模式下显示)
                    if let onDiscard = onDiscard {
                        Button(action: onDiscard) {
                            HStack {
                                Image(systemName: "trash")
                                Text("放弃")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1)) // 浅红色背景
                            .foregroundColor(.red)
                            .cornerRadius(16)
                        }
                    }
                    
                    if let onSave = onSave {
                        Button(action: onSave) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("收藏")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    // 生成明信片并分享
                    let shareImage = generatePostcardImage()
                    ShareLink(item: Image(uiImage: shareImage), preview: SharePreview("梦境明信片", image: Image(uiImage: shareImage))) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("分享")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "E0E0E0")) // 浅灰色
                        .foregroundColor(.black)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .frame(maxWidth: .infinity) // 关键修复：确保 ShareLink 本身也占满空间
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10) // 减少底部 padding，避免在小屏上太高
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 20) // 简单的 safe area 处理
                .background(
                    LinearGradient(colors: [Color(hex: "FDFBF7").opacity(0), Color(hex: "FDFBF7")], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                        .offset(y: 30)
                )
            }
        }
        .onDisappear {
            // 如果页面消失时（且不是因为保存触发的），执行清理逻辑
            // 注意：由于 onDisappear 无法区分是保存关闭还是下滑关闭，
            // 这里我们主要依赖外部传入的 onDiscard 或 ViewModel 的状态管理。
            // 为了响应“如果不点击收藏或者分享，自动删除”的需求，
            // 实际上我们应该在 View 外部（HomeView sheet）处理这个逻辑。
            // DreamResultView 本身只负责展示。
        }
    }
    
    // 生成明信片图片
    @MainActor
    private func generatePostcardImage() -> UIImage {
        let uiImage = ImageUtils.loadImage(from: dreamItem.imageUrl)
        // 设置高清宽度 (1080p 宽度作为基准)
        // 最终分辨率 = width * scale
        // 例如: 1080 * 3.0 = 3240px (宽) x 5400px (高)，约 1750万像素，达到打印级高清标准
        let targetWidth: CGFloat = 1080 
        let postcardView = DreamPostcardView(dreamItem: dreamItem, uiImage: uiImage, width: targetWidth)
        
        let renderer = ImageRenderer(content: postcardView)
        renderer.scale = 3.0 // 强制使用 3x 渲染，确保在任何设备上都是高清输出
        
        return renderer.uiImage ?? UIImage()
    }
}

struct TagSelectionView: View {
    @Bindable var dreamItem: DreamItem
    let tags = ["美梦", "噩梦", "飞行", "深海", "追逐", "童年", "未知"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    Button(action: {
                        toggleTag(tag)
                    }) {
                        Text(tag)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                dreamItem.tags.contains(tag)
                                ? Color.purple.opacity(0.1)
                                : Color.white
                            )
                            .foregroundColor(
                                dreamItem.tags.contains(tag)
                                ? Color.purple
                                : Color.gray
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        dreamItem.tags.contains(tag)
                                        ? Color.purple
                                        : Color(hex: "E0E0E0"),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }
    
    private func toggleTag(_ tag: String) {
        withAnimation {
            if dreamItem.tags.contains(tag) {
                dreamItem.tags.removeAll { $0 == tag }
            } else {
                dreamItem.tags.append(tag)
            }
        }
    }
}

// MARK: - Subviews

struct DreamImageCard: View {
    let imageUrl: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            UniversalImageView(urlString: imageUrl)
                .aspectRatio(16/9, contentMode: .fit) // 调整比例为 16:9，更宽屏更有电影感
                .clipped()
            
            HStack {
                Text(date.formatted(date: .long, time: .omitted))
                    .font(.caption)
                    .fontDesign(.serif)
                    .foregroundColor(.gray)
                    .tracking(1)
                
                Spacer()
                
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
                    .foregroundColor(.purple.opacity(0.6))
            }
            .padding(12)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16)) // 保持圆角
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5) // 柔和阴影
    }
}

struct ContentSection: View {
    let icon: String
    let title: String
    let content: String
    let fontDesign: Font.Design
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.purple)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.8))
                    .tracking(1)
            }
            
            Text(content)
                .font(.system(size: 16, weight: .regular, design: fontDesign))
                .foregroundColor(Color(UIColor.darkGray))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading) // 确保文本内容也占满宽度
        }
        .padding(18) // 增加内边距
        .frame(maxWidth: .infinity, alignment: .leading) // 确保 VStack 占满父容器宽度
        .background(Color.white)
        .cornerRadius(12) // 增大圆角
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "F0F0F0"), lineWidth: 1) // 更淡的边框
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}

struct ActionSuggestionCard: View {
    let suggestion: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf")
                    .foregroundColor(.green)
                Text("今日行动")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Text(suggestion)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(Color(UIColor.darkGray))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)
                .overlay(
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 2)
                        .padding(.vertical, 2),
                    alignment: .leading
                )
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading) // 确保文本内容也占满宽度
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading) // 确保 VStack 占满父容器宽度
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "F0F0F0"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DreamResultView(
        dreamItem: DreamItem(
            originalText: "我梦见在云端飞行，看到了一座水晶城堡...",
            imageUrl: "https://picsum.photos/600/400",
            interpretation: "飞行象征着自由和逃离束缚的渴望。水晶城堡代表着内心深处纯净而不可触及的理想。这可能意味着你最近在追求某种高尚但略显遥远的目标。",
            story: "在无尽的蔚蓝之中，我化作一缕风，掠过云海的波涛。远处，一座剔透的水晶城堡在阳光下折射出七彩的光芒，仿佛是天空的眼泪凝结而成...",
            psychologicalMapping: "飞行 -> 渴望自由\n水晶 -> 纯净/易碎\n城堡 -> 防御/理想",
            actionSuggestion: "今天，试着做一件平时不敢做的小事，打破常规，触碰你的自由。"
        ),
        onSave: {},
        onShare: {}
    )
}
