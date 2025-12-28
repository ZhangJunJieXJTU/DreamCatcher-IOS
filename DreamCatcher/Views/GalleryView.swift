import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamItem.date, order: .reverse) private var allDreams: [DreamItem]
    
    @State private var selectedTag: String? = nil
    @State private var selectedDream: DreamItem? = nil // 用于全屏查看
    
    // 固定的标签列表，实际项目中可从数据库动态聚合
    let filterTags = ["全部", "美梦", "噩梦", "飞行", "深海", "追逐", "童年", "未知"]
    
    // 过滤后的梦境
    var filteredDreams: [DreamItem] {
        if let tag = selectedTag, tag != "全部" {
            // 这里假设 DreamItem 增加了 tags 字段，或者根据内容进行简单的模拟过滤
            // 实际应匹配 item.tags.contains(tag)
            // 暂时返回所有，待数据填充完善
            return allDreams.filter { $0.tags.contains(tag) }
        }
        return allDreams
    }
    
    // Deterministic aspect ratio
    func aspectRatioForDream(_ dream: DreamItem) -> CGFloat {
        // Simple hash to determine aspect ratio: 3:4 (0.75) or 1:1 (1.0)
        let hash = dream.id.hashValue
        return abs(hash) % 2 == 0 ? 0.75 : 1.0
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部标题
                HStack(alignment: .bottom) {
                    Text("浮生梦廊")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(filteredDreams.count) 个梦境碎片")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.bottom, 6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // 情绪筛选器 (Chips)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filterTags, id: \.self) { tag in
                            Button(action: {
                                withAnimation {
                                    selectedTag = tag == "全部" ? nil : tag
                                }
                            }) {
                                Text(tag)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        (selectedTag == tag || (selectedTag == nil && tag == "全部"))
                                        ? Color.white
                                        : Color.gray.opacity(0.3)
                                    )
                                    .foregroundColor(
                                        (selectedTag == tag || (selectedTag == nil && tag == "全部"))
                                        ? .black
                                        : .gray
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
                
                // 瀑布流网格
                ScrollView {
                    HStack(alignment: .top, spacing: 12) {
                        // 左列
                        LazyVStack(spacing: 12) {
                            ForEach(leftColumnDreams) { dream in
                                GalleryItemView(dream: dream, aspectRatio: aspectRatioForDream(dream))
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedDream = dream
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteDream(dream)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        
                        // 右列
                        LazyVStack(spacing: 12) {
                            ForEach(rightColumnDreams) { dream in
                                GalleryItemView(dream: dream, aspectRatio: aspectRatioForDream(dream))
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedDream = dream
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteDream(dream)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // 避开 TabBar
                }
            }
            
            // 全屏查看 (Detail)
            if let dream = selectedDream {
                DreamResultView(
                    dreamItem: dream,
                    onSave: nil, // 浏览模式下不显示保存按钮
                    onShare: {
                        // Share logic here
                    }
                )
                .transition(.opacity)
                .zIndex(100)
                .overlay(
                    HStack(spacing: 16) {
                        // 删除按钮
                        Button(action: {
                            deleteDream(dream)
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(4)
                        }
                        
                        // 关闭按钮
                        Button(action: {
                            withAnimation {
                                selectedDream = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(4)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 16),
                    alignment: .topTrailing
                )
            }
        }
    }
    
    private func deleteDream(_ dream: DreamItem) {
        withAnimation {
            if selectedDream == dream {
                selectedDream = nil
            }
            modelContext.delete(dream)
        }
    }
    
    // 简单的左右分列逻辑
    var leftColumnDreams: [DreamItem] {
        filteredDreams.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
    }
    
    var rightColumnDreams: [DreamItem] {
        filteredDreams.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
    }
}

struct GalleryItemView: View {
    let dream: DreamItem
    let aspectRatio: CGFloat
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 图片
            UniversalImageView(urlString: dream.imageUrl)
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.8), .transparent], startPoint: .bottom, endPoint: .center)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                // 日期
                Text(dream.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
                
                // 内容预览
                Text(dream.story.isEmpty ? dream.originalText : dream.story)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                // 标签
                if !dream.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(dream.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(12)
        }
        .cornerRadius(16)
        .contentShape(Rectangle()) // 优化点击区域
    }
}

extension Color {
    static let transparent = Color.white.opacity(0)
}



#Preview {
    GalleryView()
        .modelContainer(for: DreamItem.self, inMemory: true)
}
